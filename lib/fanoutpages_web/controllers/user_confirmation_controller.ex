defmodule FanoutpagesWeb.UserConfirmationController do
  use FanoutpagesWeb, :controller

  alias Fanoutpages.Accounts

  def update_email(conn, %{"token" => token}) do
    user = conn.assigns[:current_user]

    case Accounts.update_user_email(user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email updated successfully.")
        |> redirect(to: ~p"/settings/profile")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or has expired.")
        |> redirect(to: ~p"/settings/profile")
    end
  end
end
