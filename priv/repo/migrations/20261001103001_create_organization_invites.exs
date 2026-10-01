defmodule Fanoutpages.Repo.Migrations.CreateOrganizationInvites do
  use Ecto.Migration

  def change do
    create table(:organization_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :invited_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :email, :citext, null: false
      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :accepted_at, :utc_datetime
      add :revoked_at, :utc_datetime
      add :last_sent_at, :utc_datetime
      add :send_count, :integer, default: 1, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_invites, [:token])
    create index(:organization_invites, [:organization_id])
    create index(:organization_invites, [:email])

    create unique_index(:organization_invites, [:organization_id, :email],
             name: :organization_invites_pending_email_index,
             where: "accepted_at IS NULL AND revoked_at IS NULL"
           )
  end
end
