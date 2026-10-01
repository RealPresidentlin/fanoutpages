defmodule Fanoutpages.Repo.Migrations.CreatePaymentEvents do
  use Ecto.Migration

  def change do
    create table(:payment_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :provider, :string, null: false, default: "polar"
      add :provider_event_id, :string
      add :provider_webhook_id, :string
      add :event_type, :string, null: false
      add :resource_type, :string
      add :resource_id, :string
      add :polar_customer_id, :string
      add :polar_subscription_id, :string
      add :polar_order_id, :string
      add :polar_product_id, :string
      add :polar_price_id, :string
      add :status, :string, null: false, default: "received"
      add :processed_at, :utc_datetime
      add :error_message, :text
      add :attempt_count, :integer, null: false, default: 0
      add :payload_sha256, :string
      add :payload, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:payment_events, [:organization_id])
    create index(:payment_events, [:event_type])
    create index(:payment_events, [:status])
    create index(:payment_events, [:provider_webhook_id])
    create index(:payment_events, [:provider_event_id])
    create index(:payment_events, [:resource_type, :resource_id])

    create unique_index(:payment_events, [:provider, :provider_webhook_id],
             where: "provider_webhook_id IS NOT NULL"
           )

    create unique_index(:payment_events, [:provider, :provider_event_id],
             where: "provider_event_id IS NOT NULL"
           )
  end
end
