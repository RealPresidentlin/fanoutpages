defmodule Fanoutpages.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

 def change do
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :created_by_user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      add :plan, :string, null: false, default: "core"
      add :subscription_status, :string, null: false, default: "trialing"
      add :started_at, :utc_datetime
      add :ends_at, :utc_datetime
      add :polar_customer_id, :string
      add :polar_subscription_id, :string
      add :polar_product_id, :string
      add :polar_price_id, :string
      add :polar_checkout_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])
    create index(:organizations, [:created_by_user_id])
    create index(:organizations, [:plan])
    create index(:organizations, [:subscription_status])
    create index(:organizations, [:ends_at])
    create index(:organizations, [:polar_customer_id])
    create index(:organizations, [:polar_subscription_id])
    create index(:organizations, [:polar_product_id])

    create constraint(:organizations, :organizations_plan_must_be_valid,
             check: "plan IN ('core', 'scale', 'pro', 'enterprise')"
           )

    create constraint(:organizations, :organizations_subscription_status_must_be_valid,
             check:
               "subscription_status IN ('trialing', 'active', 'expired', 'canceled', 'past_due')"
           )
  end
end
