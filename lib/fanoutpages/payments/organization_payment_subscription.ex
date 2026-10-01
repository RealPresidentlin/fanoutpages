defmodule Fanoutpages.Payments.OrganizationPaymentSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_payment_subscriptions" do
    belongs_to :organization, Fanoutpages.Organizations.Organization

    field :polar_subscription_id, :string
    field :polar_customer_id, :string
    field :polar_price_id, :string
    field :polar_product_id, :string
    field :polar_product_name, :string
    field :polar_checkout_id, :string
    field :plan, :string
    field :status, :string
    field :amount_cents, :integer
    field :currency, :string
    field :current_period_start, :utc_datetime
    field :current_period_end, :utc_datetime
    field :started_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :canceled_at, :utc_datetime
    field :ended_at, :utc_datetime
    field :provider_modified_at, :utc_datetime
    field :cancel_at_period_end, :boolean, default: false
    field :metadata, :map, default: %{}
    field :raw_event, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :organization_id,
      :polar_subscription_id,
      :polar_customer_id,
      :polar_price_id,
      :polar_product_id,
      :polar_product_name,
      :polar_checkout_id,
      :plan,
      :status,
      :amount_cents,
      :currency,
      :current_period_start,
      :current_period_end,
      :started_at,
      :ends_at,
      :canceled_at,
      :ended_at,
      :provider_modified_at,
      :cancel_at_period_end,
      :metadata,
      :raw_event
    ])
    |> validate_required([:organization_id, :polar_subscription_id, :plan, :status])
    |> validate_inclusion(:plan, ["core", "scale", "pro", "enterprise"])
    |> unique_constraint(:polar_subscription_id)
  end
end
