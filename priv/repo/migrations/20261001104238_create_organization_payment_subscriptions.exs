defmodule Fanoutpages.Repo.Migrations.CreateOrganizationPaymentSubscriptions do
  use Ecto.Migration

  def change do
    create table(:organization_payment_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :polar_subscription_id, :string, null: false
      add :polar_customer_id, :string
      add :polar_price_id, :string
      add :polar_product_id, :string
      add :polar_product_name, :string
      add :polar_checkout_id, :string
      add :plan, :string, null: false
      add :status, :string, null: false
      add :amount_cents, :integer
      add :currency, :string
      add :current_period_start, :utc_datetime
      add :current_period_end, :utc_datetime
      add :started_at, :utc_datetime
      add :ends_at, :utc_datetime
      add :canceled_at, :utc_datetime
      add :ended_at, :utc_datetime
      add :provider_modified_at, :utc_datetime
      add :cancel_at_period_end, :boolean, default: false, null: false
      add :metadata, :map, default: %{}, null: false
      add :raw_event, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_payment_subscriptions, [:polar_subscription_id])
    create index(:organization_payment_subscriptions, [:organization_id])
    create index(:organization_payment_subscriptions, [:polar_customer_id])

    create constraint(
             :organization_payment_subscriptions,
             :organization_payment_subscriptions_plan_must_be_valid,
             check: "plan IN ('starter', 'business', 'core', 'scale', 'pro', 'enterprise')"
           )
  end
end
