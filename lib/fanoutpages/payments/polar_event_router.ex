defmodule Fanoutpages.Payments.PolarEventRouter do
  @moduledoc """
  Routes Polar webhook events to database changes.
  """
  alias Fanoutpages.{Organizations, Payments, Repo}
  alias Fanoutpages.Billing.PlanConfig
  alias Fanoutpages.Payments.PaymentEvent

  @subscription_events [
    "subscription.created",
    "subscription.updated",
    "subscription.active",
    "subscription.canceled",
    "subscription.revoked"
  ]

  @subscription_statuses ~w(incomplete incomplete_expired trialing active past_due canceled unpaid)

  def handle(event, webhook_id) do
    event_type = event["type"] || event["event_type"] || "unknown"
    data = event["data"] || %{}
    receipt_attrs = resource_attrs(data) |> Map.put(:payload_sha256, payload_sha256(event))

    with result when result in [:recorded, :duplicate] <-
           Payments.record_webhook_once(webhook_id, event_type, receipt_attrs),
         {:ok, payment_event} <- fetch_or_record_event(event, webhook_id, event_type, data),
         :continue <- processing_decision(payment_event),
         {:ok, payment_event} <- Payments.mark_payment_event_processing(payment_event) do
      process_and_mark(event_type, data, payment_event)
    else
      :already_processed -> :ok
      {:error, reason} -> {:error, reason}
      other -> {:error, other}
    end
  end
end
