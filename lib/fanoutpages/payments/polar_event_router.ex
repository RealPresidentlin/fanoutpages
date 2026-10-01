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

  defp subscription_attrs(data) do
    subscription_id = subscription_id(data, "subscription")

    with true <- is_binary(subscription_id) || {:error, :missing_subscription_id},
         product_id when is_binary(product_id) <- product_id(data),
         plan when is_binary(plan) <- PlanConfig.plan_from_product_id(product_id),
         status when status in @subscription_statuses <- normalize_status(data["status"]) do
      {:ok,
       %{
         polar_subscription_id: subscription_id,
         polar_customer_id: customer_id(data),
         polar_price_id: price_id(data),
         polar_product_id: product_id,
         polar_product_name: nested(data, [["product", "name"]]),
         polar_checkout_id: nested(data, [["checkout_id"], ["checkout", "id"]]),
         plan: plan,
         status: status,
         amount_cents: amount(data),
         currency: data["currency"],
         current_period_start: parse_datetime(data["current_period_start"]),
         current_period_end: parse_datetime(data["current_period_end"]),
         started_at: parse_datetime(data["started_at"]),
         ends_at: parse_datetime(data["ends_at"]),
         canceled_at: parse_datetime(data["canceled_at"]),
         ended_at: parse_datetime(data["ended_at"]),
         provider_modified_at: parse_datetime(data["modified_at"]),
         cancel_at_period_end: cancel_at_period_end?(data),
         metadata: data["metadata"] || %{},
         raw_event: data
       }}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :unknown_polar_product}
      "unknown" -> {:error, :unknown_subscription_status}
      _status -> {:error, :unknown_subscription_status}
    end
  end

  defp organization_attrs(attrs) do
    status = attrs.status

    %{
      plan: attrs.plan,
      subscription_status: organization_status(status),
      polar_customer_id: attrs.polar_customer_id,
      polar_subscription_id: attrs.polar_subscription_id,
      polar_product_id: attrs.polar_product_id,
      polar_price_id: attrs.polar_price_id,
      polar_checkout_id: attrs.polar_checkout_id,
      current_period_start: attrs.current_period_start,
      current_period_end: attrs.current_period_end,
      ends_at: attrs.ends_at,
      cancel_at_period_end: attrs.cancel_at_period_end,
      started_at: attrs.started_at
    }
  end

  defp organization_status(status) when status in ["active", "trialing"], do: status
  defp organization_status("past_due"), do: "past_due"
  defp organization_status("canceled"), do: "canceled"
  defp organization_status("unpaid"), do: "expired"
  defp organization_status(_status), do: "expired"

  defp normalize_status(nil), do: "unknown"
  defp normalize_status(status), do: String.downcase(status)

  defp cancel_at_period_end?(data) do
    data["cancel_at_period_end"] == true ||
      (is_binary(data["cancel_at"]) and is_nil(data["ended_at"]))
  end

  defp resource_attrs(data) do
    %{
      resource_type: data["type"],
      resource_id: data["id"]
    }
  end

  defp customer_id(data),
    do: nested(data, [["customer_id"], ["customer", "id"]])

  defp subscription_id(data, event_type) do
    nested(data, [
      ["subscription_id"],
      ["subscription", "id"],
      if(String.starts_with?(event_type, "subscription"), do: ["id"], else: [])
    ])
  end

  defp order_id(data, event_type) do
    nested(data, [
      ["order_id"],
      ["order", "id"],
      if(String.starts_with?(event_type, "order"), do: ["id"], else: [])
    ])
  end
end
