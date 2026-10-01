defmodule Fanoutpages.Workspaces.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workspaces" do
    field :name, :string
    field :slug, :string
    field :archived_at, :utc_datetime

    belongs_to :organization, Fanoutpages.Organizations.Organization
    has_many :memberships, Fanoutpages.Workspaces.WorkspaceMembership
    has_many :users, through: [:memberships, :user]
    has_many :invites, Fanoutpages.Workspaces.WorkspaceInvite

    timestamps(type: :utc_datetime)
  end

  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :slug, :organization_id, :archived_at])
    |> validate_required([:name, :slug, :organization_id])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:slug, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
    |> unique_constraint(:slug)
  end
end
