defmodule FanoutpagesWeb.UserSessionController do
  use FanoutpagesWeb, :controller

  alias Fanoutpages.Accounts
  alias FanoutpagesWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    auto_login(conn, params)
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    auto_login(conn, params)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp auto_login(conn, %{"user" => %{"email" => email, "password" => password}} = params) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, params["user"])
    else
      redirect(conn, to: ~p"/users/log_in")
    end
  end

  defp auto_login(conn, _params) do
    redirect(conn, to: ~p"/users/log_in")
  end
end
