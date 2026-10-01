defmodule FanoutpagesWeb.WorkspaceController do
  use FanoutpagesWeb, :controller

  alias Fanoutpages.Workspaces

  def index(conn, _params) do
    user = conn.assigns[:current_user]
    scope = conn.assigns[:current_scope]

    workspace =
      (scope && scope.workspace) ||
        (user &&
           case Workspaces.default_scope(user, get_session(conn, :current_workspace_slug)) do
             %{workspace: %{} = ws} -> ws
             _ -> nil
           end)

    case workspace do
      %{slug: slug} when is_binary(slug) ->
        redirect(conn, to: ~p"/w/#{slug}/dashboard")

      _ ->
        case conn.assigns[:current_organization] do
          %{id: _} ->
            redirect(conn, to: ~p"/workspaces")

          _ ->
            conn
            |> put_flash(:error, "No workspace or brand found.")
            |> redirect(to: ~p"/")
        end
    end
  end
end
