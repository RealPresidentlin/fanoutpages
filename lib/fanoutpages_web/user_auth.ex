defmodule FanoutpagesWeb.UserAuth do
  @moduledoc """
  Authentication helpers for Plug and LiveView.
  """

  use FanoutpagesWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Fanoutpages.Accounts
  alias Fanoutpages.Workspaces
  alias Phoenix.Component

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_fanoutpages_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    user_return_to =
      safe_return_path(Map.get(params, "return_to") || get_session(conn, :user_return_to))

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> delete_session(:user_return_to)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  def log_out_user(conn) do
    if token = get_session(conn, :user_token) do
      Accounts.delete_user_session_token(token)
    end

    if live_socket_id = get_session(conn, :live_socket_id) do
      FanoutpagesWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  def fetch_current_organization(conn, _opts) do
    user = conn.assigns[:current_user]
    workspace_slug = get_session(conn, :current_workspace_slug)

    scope = user && Workspaces.default_scope(user, workspace_slug)

    conn
    |> assign(:current_scope, scope)
    |> assign(:current_membership, scope && scope.organization_membership)
    |> assign(:current_organization, scope && scope.organization)
    |> assign(:current_workspace, scope && scope.workspace)
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn |> redirect(to: signed_in_path(conn)) |> halt()
    else
      conn
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to continue.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  def fetch_workspace_from_path(conn, _opts) do
    case {
      conn.assigns[:current_user],
      conn.path_params["workspace_slug"]
    } do
      {%{} = user, slug} when is_binary(slug) ->
        case Workspaces.get_accessible_by_slug(user, slug) do
          nil ->
            conn
            |> put_flash(:error, "You do not have access to that workspace.")
            |> redirect(to: ~p"/dashboard")
            |> halt()

          scope ->
            conn
            |> put_session(:current_workspace_slug, slug)
            |> assign(:current_scope, scope)
            |> assign(:current_membership, scope.organization_membership)
            |> assign(:current_organization, scope.organization)
            |> assign(:current_workspace, scope.workspace)
        end

      _ ->
        conn
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:load_current_workspace, %{"workspace_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user

    case Workspaces.get_accessible_by_slug(user, slug) do
      nil ->
        {:halt,
         socket
         |> Phoenix.LiveView.put_flash(:error, "You do not have access to that workspace.")
         |> Phoenix.LiveView.redirect(to: ~p"/dashboard")}

      scope ->
        {:cont,
         socket
         |> Component.assign(:current_scope, scope)
         |> Component.assign(:current_membership, scope.organization_membership)
         |> Component.assign(:current_organization, scope.organization)
         |> Component.assign(:current_workspace, scope.workspace)}
    end
  end

  def on_mount(:load_current_workspace, _params, _session, socket) do
    {:cont, socket}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "You must log in to continue.")
       |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    socket =
      Component.assign_new(socket, :current_user, fn ->
        if token = session["user_token"] do
          Accounts.get_user_by_session_token(token)
        end
      end)

    socket =
      Component.assign_new(socket, :current_scope, fn ->
        if socket.assigns.current_user do
          Workspaces.default_scope(
            socket.assigns.current_user,
            session["current_workspace_slug"]
          )
        end
      end)

    scope = socket.assigns.current_scope

    socket
    |> Component.assign_new(:current_membership, fn ->
      scope && scope.organization_membership
    end)
    |> Component.assign_new(:current_organization, fn -> scope && scope.organization end)
    |> Component.assign_new(:current_workspace, fn -> scope && scope.workspace end)
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params), do: conn

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  def safe_return_path(path) when is_binary(path) do
    uri = URI.parse(path)

    if String.starts_with?(path, "/") and not String.starts_with?(path, "//") and
         is_nil(uri.scheme) and is_nil(uri.host),
       do: path,
       else: nil
  end

  def safe_return_path(_), do: nil

  defp signed_in_path(_conn), do: ~p"/dashboard"
end
