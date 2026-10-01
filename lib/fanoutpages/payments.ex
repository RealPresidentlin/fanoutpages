defmodule Fanoutpages.Payments do
  @moduledoc """
  The Payments context handling Polar subscriptions, transactions, and event storage.
  """

  import Ecto.Query, warn: false
  alias Fanoutpages.Repo
  alias Fanoutpages.Organizations

  alias Fanoutpages.Payments.{
    OrganizationPaymentSubscription,
    OrganizationPaymentTransaction,
    PolarWebhookReceipt,
    PaymentEvent
  }

  def get_subscription_by_polar_id(polar_subscription_id)
      when is_binary(polar_subscription_id) do
    Repo.get_by(OrganizationPaymentSubscription, polar_subscription_id: polar_subscription_id)
  end

  def get_current_subscription(organization_id) do
    from(s in OrganizationPaymentSubscription,
      where: s.organization_id == ^organization_id and s.status in ["active", "trialing"],
      order_by: [desc: s.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def list_transactions(organization_id) do
    from(t in OrganizationPaymentTransaction,
      where: t.organization_id == ^organization_id,
      order_by: [desc: t.transaction_date, desc: t.inserted_at]
    )
    |> Repo.all()
  end

  def record_webhook_once(webhook_id, event_type, attrs) do
    %PolarWebhookReceipt{}
    |> PolarWebhookReceipt.changeset(
      Map.merge(attrs, %{webhook_id: webhook_id, event_type: event_type})
    )
    |> Repo.insert()
    |> case do
      {:ok, _receipt} -> :recorded
      {:error, %{errors: [webhook_id: {"has already been taken", _}]}} -> :duplicate
      {:error, reason} -> {:error, reason}
    end
  end

  def get_payment_event_by_webhook_id(webhook_id) when is_binary(webhook_id) do
    Repo.get_by(PaymentEvent, provider_webhook_id: webhook_id)
  end

  def record_payment_event(attrs) do
    %PaymentEvent{}
    |> PaymentEvent.changeset(attrs)
    |> Repo.insert()
  end

  def mark_payment_event_processing(%PaymentEvent{} = event) do
    event
    |> PaymentEvent.changeset(%{status: "processing", attempt_count: event.attempt_count + 1})
    |> Repo.update()
  end

  def mark_payment_event_processed(%PaymentEvent{} = event) do
    event
    |> PaymentEvent.changeset(%{
      status: "processed",
      processed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      error_message: nil
    })
    |> Repo.update()
  end

  def mark_payment_event_failed(%PaymentEvent{} = event, reason) do
    event
    |> PaymentEvent.changeset(%{
      status: "failed",
      error_message: inspect(reason)
    })
    |> Repo.update()
  end

  def sync_subscription(organization, subscription_attrs, organization_attrs) do
    polar_sub_id = subscription_attrs.polar_subscription_id

    subscription =
      get_subscription_by_polar_id(polar_sub_id) ||
        %OrganizationPaymentSubscription{organization_id: organization.id}

    subscription_changeset =
      OrganizationPaymentSubscription.changeset(subscription, subscription_attrs)

    organization_changeset =
      Organizations.Organization.plan_changeset(organization, organization_attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_or_update(:subscription, subscription_changeset)
    |> Ecto.Multi.update(:organization, organization_changeset)
    |> Repo.transaction()
  end
end
