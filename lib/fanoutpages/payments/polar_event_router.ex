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
  end
end
