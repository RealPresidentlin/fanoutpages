defmodule Fanoutpages.Repo.Migrations.CreateUserIdentities do
  use Ecto.Migration

  def change do
    create table(:user_identities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :provider, :string, null: false
      add :access_token, :text
      add :refresh_token, :text
      add :token_type, :string
      add :expires_at, :utc_datetime
      add :scopes, {:array, :string}, default: []
      add :raw_info, :map
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:user_identities, [:user_id])
    create unique_index(:user_identities, [:provider, :user_id])
  end
end
