defmodule Fanoutpages.Workspaces.WorkspaceInvite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workspace_invites" do
    field :email, :string
    field :token, :string
    field :expires_at, :utc_datetime
    field :accepted_at, :utc_datetime
    field :revoked_at, :utc_datetime

    belongs_to :workspace, Fanoutpages.Workspaces.Workspace
    belongs_to :invited_by_user, Fanoutpages.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :token, :expires_at, :workspace_id, :invited_by_user_id])
    |> validate_required([:email, :token, :expires_at, :workspace_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:token)
  end
end
