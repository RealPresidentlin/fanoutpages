defmodule FanoutpagesWeb.PolarWebhookController do
  use FanoutpagesWeb, :controller

  alias Fanoutpages.Polar.Webhook
  alias Fanoutpages.Workers.PolarWebhookWorker

  def create(conn, _params) do
    with {:ok, raw_body, conn} <- Plug.Conn.read_body(conn),
         webhook_id when is_binary(webhook_id) <- get_header(conn, "webhook-id"),
         timestamp when is_binary(timestamp) <- get_header(conn, "webhook-timestamp"),
         signature when is_binary(signature) <- get_header(conn, "webhook-signature"),
         :ok <- Webhook.verify(raw_body, webhook_id, timestamp, signature),
         {:ok, payload} <- Jason.decode(raw_body) do
      %{"event" => payload, "webhook_id" => webhook_id}
      |> PolarWebhookWorker.new()
      |> Oban.insert()

      send_resp(conn, 202, "")
    else
      {:error, :invalid_signature} ->
        send_resp(conn, 400, "invalid webhook signature")

      _ ->
        send_resp(conn, 400, "bad request")
    end
  end

  defp get_header(conn, header_name) do
    case get_req_header(conn, header_name) do
      [value | _] -> value
      _ -> nil
    end
  end
end
