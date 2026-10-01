defmodule Fanoutpages.Payments.OrganizationPaymentTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_payment_transactions" do
    belongs_to :organization, Fanoutpages.Organizations.Organization

    belongs_to :subscription,
               Fanoutpages.Payments.OrganizationPaymentSubscription,
               foreign_key: :subscription_id

    field :polar_transaction_id, :string
    field :polar_event_id, :string
    field :polar_customer_id, :string
    field :status, :string
    field :transaction_date, :utc_datetime
    field :amount_cents, :integer
    field :tax_amount_cents, :integer
    field :discount_amount_cents, :integer
    field :currency, :string
    field :metadata, :map, default: %{}
    field :raw_event, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :organization_id,
      :subscription_id,
      :polar_transaction_id,
      :polar_event_id,
      :polar_customer_id,
      :status,
      :transaction_date,
      :amount_cents,
      :tax_amount_cents,
      :discount_amount_cents,
      :currency,
      :metadata,
      :raw_event
    ])
    |> validate_required([:organization_id, :status])
    |> unique_constraint(:polar_transaction_id)
    |> unique_constraint(:polar_event_id)
  end
end
