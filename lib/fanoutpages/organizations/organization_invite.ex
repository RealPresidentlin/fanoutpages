defmodule Fanoutpages.Organizations.OrganizationInvite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ~w(admin member)

  schema "organization_invites" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :expires_at, :utc_datetime
    field :accepted_at, :utc_datetime
    field :revoked_at, :utc_datetime
    field :last_sent_at, :utc_datetime
    field :send_count, :integer, default: 1

    belongs_to :organization, Fanoutpages.Organizations.Organization
    belongs_to :invited_by_user, Fanoutpages.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [
      :email,
      :role,
      :token,
      :expires_at,
      :accepted_at,
      :revoked_at,
      :last_sent_at,
      :send_count,
      :organization_id,
      :invited_by_user_id
    ])
    |> validate_required([
      :email,
      :role,
      :token,
      :expires_at,
      :organization_id,
      :invited_by_user_id
    ])
    |> validate_email()
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:token)
    |> unique_constraint([:organization_id, :email],
      name: :organization_invites_pending_email_index,
      message: "already has a pending invite for this organization"
    )
  end

  def active?(%__MODULE__{accepted_at: nil, revoked_at: nil, expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  def active?(_invite), do: false

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def roles, do: @roles
end
