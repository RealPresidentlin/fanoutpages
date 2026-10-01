defmodule Fanoutpages.Payments.PaymentEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "payment_events" do
    belongs_to :organization, Fanoutpages.Organizations.Organization

    field :provider, :string, default: "polar"
    field :provider_event_id, :string
    field :provider_webhook_id, :string
    field :event_type, :string
    field :resource_type, :string
    field :resource_id, :string
    field :polar_customer_id, :string
    field :polar_subscription_id, :string
    field :polar_order_id, :string
    field :polar_product_id, :string
    field :polar_price_id, :string
    field :status, :string, default: "received"
    field :processed_at, :utc_datetime
    field :error_message, :string
    field :attempt_count, :integer, default: 0
    field :payload_sha256, :string
    field :payload, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :organization_id,
      :provider,
      :provider_event_id,
      :provider_webhook_id,
      :event_type,
      :resource_type,
      :resource_id,
      :polar_customer_id,
      :polar_subscription_id,
      :polar_order_id,
      :polar_product_id,
      :polar_price_id,
      :status,
      :processed_at,
      :error_message,
      :attempt_count,
      :payload_sha256,
      :payload
    ])
    |> validate_required([:event_type, :status])
  end
end
