defmodule FanoutpagesWeb.WorkspaceSwitchController do
  use FanoutpagesWeb, :controller

  alias Fanoutpages.Workspaces

  def switch(conn, %{"slug" => slug}) do
    user = conn.assigns[:current_user]

    case Workspaces.get_accessible_by_slug(user, slug) do
      nil ->
        conn
        |> put_flash(:error, "Workspace not found or access denied.")
        |> redirect(to: ~p"/workspaces")

      _scope ->
        conn
        |> put_session(:current_workspace_slug, slug)
        |> redirect(to: ~p"/w/#{slug}/dashboard")
    end
  end
end
