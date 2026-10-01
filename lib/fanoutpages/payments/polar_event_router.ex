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
end
