defmodule Fanoutpages.Repo.Migrations.CreatePolarWebhookReceipts do
  use Ecto.Migration

  def change do
    create table(:polar_webhook_receipts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :webhook_id, :string, null: false
      add :event_type, :string, null: false
      add :payload_sha256, :string
      add :resource_type, :string
      add :resource_id, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:polar_webhook_receipts, [:webhook_id])
    create index(:polar_webhook_receipts, [:event_type])
    create index(:polar_webhook_receipts, [:resource_type, :resource_id])
  end
end
