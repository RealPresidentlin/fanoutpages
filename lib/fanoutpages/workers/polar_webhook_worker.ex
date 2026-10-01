defmodule Fanoutpages.Workers.PolarWebhookWorker do
  @moduledoc "Oban worker for asynchronously routing Polar webhook payloads."
  use Oban.Worker, queue: :payments, max_attempts: 5

  alias Fanoutpages.Payments.PolarEventRouter

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"event" => event, "webhook_id" => webhook_id}}) do
    case PolarEventRouter.handle(event, webhook_id) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
      other -> {:error, other}
    end
  end
end
