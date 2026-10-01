defmodule FanoutpagesWeb.PageController do
  use FanoutpagesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
