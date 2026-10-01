defmodule Fanoutpages.Repo.Migrations.CreateOrganizationPaymentTransactions do
  use Ecto.Migration

  def change do
    create table(:organization_payment_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :subscription_id,
          references(:organization_payment_subscriptions,
            type: :binary_id,
            on_delete: :nilify_all
          )

      add :polar_transaction_id, :string
      add :polar_event_id, :string
      add :polar_customer_id, :string
      add :status, :string, null: false
      add :transaction_date, :utc_datetime
      add :amount_cents, :integer
      add :tax_amount_cents, :integer
      add :discount_amount_cents, :integer
      add :currency, :string
      add :metadata, :map, default: %{}, null: false
      add :raw_event, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_payment_transactions, [:polar_transaction_id])
    create unique_index(:organization_payment_transactions, [:polar_event_id])
    create index(:organization_payment_transactions, [:organization_id])
  end
end
