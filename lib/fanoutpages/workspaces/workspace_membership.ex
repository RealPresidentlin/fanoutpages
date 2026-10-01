defmodule Fanoutpages.Workspaces.WorkspaceMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workspace_memberships" do
    belongs_to :workspace, Fanoutpages.Workspaces.Workspace
    belongs_to :user, Fanoutpages.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:workspace_id, :user_id])
    |> validate_required([:workspace_id, :user_id])
    |> unique_constraint([:workspace_id, :user_id])
  end
end
