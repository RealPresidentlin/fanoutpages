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

  defp process_and_mark(event_type, data, payment_event) do
    with :ok <- process_event(event_type, data, payment_event),
         {:ok, _payment_event} <- Payments.mark_payment_event_processed(payment_event) do
      :ok
    else
      {:error, reason} ->
        Payments.mark_payment_event_failed(payment_event, reason)
        {:error, reason}

      reason ->
        Payments.mark_payment_event_failed(payment_event, reason)
        {:error, reason}
    end
  end

  defp fetch_or_record_event(event, webhook_id, event_type, data) do
    case Payments.get_payment_event_by_webhook_id(webhook_id) do
      %PaymentEvent{} = payment_event ->
        {:ok, payment_event}

      nil ->
        attrs =
          data
          |> resource_attrs()
          |> Map.merge(%{
            provider: "polar",
            provider_event_id: event["id"],
            provider_webhook_id: webhook_id,
            event_type: event_type,
            payload_sha256: payload_sha256(event),
            payload: event,
            status: "received",
            polar_customer_id: customer_id(data),
            polar_subscription_id: subscription_id(data, event_type),
            polar_order_id: order_id(data, event_type),
            polar_product_id: product_id(data),
            polar_price_id: price_id(data)
          })

        Payments.record_payment_event(attrs)
    end
  end

  defp processing_decision(%PaymentEvent{status: "processed"}), do: :already_processed
  defp processing_decision(%PaymentEvent{}), do: :continue

  defp process_event(event_type, data, payment_event) when event_type in @subscription_events do
    with {:ok, organization} <- resolve_organization(data),
         {:ok, subscription_attrs} <- subscription_attrs(data),
         {:ok, _sync_result} <-
           Payments.sync_subscription(
             organization,
             subscription_attrs,
             organization_attrs(subscription_attrs)
           ) do
      maybe_attach_organization(payment_event, organization.id)
    end
  end

  defp process_event(event_type, data, payment_event)
       when event_type in ["order.paid", "checkout.created", "checkout.updated"] do
    case resolve_organization(data) do
      {:ok, organization} -> maybe_attach_organization(payment_event, organization.id)
      {:error, :organization_not_found} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp process_event(_event_type, _data, _payment_event), do: :ok

  defp maybe_attach_organization(%PaymentEvent{} = event, org_id) do
    event
    |> PaymentEvent.changeset(%{organization_id: org_id})
    |> Repo.update()
    |> case do
      {:ok, _event} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_organization(data) do
    org_id = get_in(data, ["metadata", "organization_id"])

    case Organizations.get_organization(org_id) do
      nil -> {:error, :organization_not_found}
      org -> {:ok, org}
    end
  end
end
