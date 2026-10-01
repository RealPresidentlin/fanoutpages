defmodule FanoutpagesWeb.CacheBodyReader do
  @moduledoc false

  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} -> {:ok, body, cache_body(conn, body)}
      {:more, body, conn} -> {:more, body, cache_body(conn, body)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp cache_body(conn, body) do
    if match?(["webhooks" | _], conn.path_info) and is_binary(body) do
      Plug.Conn.assign(conn, :raw_body, [body | List.wrap(conn.assigns[:raw_body])])
    else
      conn
    end
  end
end
