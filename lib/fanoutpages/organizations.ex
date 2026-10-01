defmodule Fanoutpages.Organizations do
  @moduledoc """
  The Organizations context for tenant management.
  """

  import Ecto.Query, warn: false
  alias Fanoutpages.Repo

  alias Fanoutpages.Organizations.{
    Organization,
    OrganizationMembership,
    OrganizationInvite,
    OrganizationNotifier
  }

  alias Fanoutpages.Billing.PlanConfig
  alias Fanoutpages.Workspaces

  def get_organization(id) when is_binary(id) do
    Repo.get(Organization, id)
  end

  def get_organization!(id) do
    Repo.get!(Organization, id)
  end

  def get_organization_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Organization, slug: slug)
  end

  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  def list_organizations_for_user(user) do
    from(o in Organization,
      join: m in OrganizationMembership,
      on: m.organization_id == o.id,
      where: m.user_id == ^user.id,
      order_by: [asc: o.name]
    )
    |> Repo.all()
  end

  def list_members(organization_id) do
    from(m in OrganizationMembership,
      where: m.organization_id == ^organization_id,
      join: u in assoc(m, :user),
      preload: [user: u],
      order_by: [asc: m.role, asc: u.name]
    )
    |> Repo.all()
  end

  def count_members(organization_id) do
    from(m in OrganizationMembership,
      where: m.organization_id == ^organization_id
    )
    |> Repo.aggregate(:count, :id)
  end

  def list_pending_invites(organization_id) do
    now = DateTime.utc_now()

    from(i in OrganizationInvite,
      where:
        i.organization_id == ^organization_id and is_nil(i.accepted_at) and
          is_nil(i.revoked_at) and i.expires_at > ^now,
      join: u in assoc(i, :invited_by_user),
      preload: [invited_by_user: u],
      order_by: [desc: i.inserted_at]
    )
    |> Repo.all()
  end

  def get_invite_by_token(token) when is_binary(token) do
    Repo.get_by(OrganizationInvite, token: token)
    |> Repo.preload([:organization, :invited_by_user])
  end

  def create_invite(organization, attrs, current_user, invite_url_fun) do
    current_human_count = count_members(organization.id)
    limits = PlanConfig.limits(organization.plan)

    if limits.max_humans != :unlimited and current_human_count >= limits.max_humans do
      {:error, :quota_exceeded}
    else
      token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
      expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)

      invite_attrs =
        attrs
        |> Map.merge(%{
          "token" => token,
          "expires_at" => expires_at,
          "organization_id" => organization.id,
          "invited_by_user_id" => current_user.id,
          "last_sent_at" => DateTime.utc_now() |> DateTime.truncate(:second)
        })

      %OrganizationInvite{}
      |> OrganizationInvite.changeset(invite_attrs)
      |> Repo.insert()
      |> case do
        {:ok, invite} ->
          invite = Repo.preload(invite, [:organization])
          OrganizationNotifier.deliver_organization_invite(invite, invite_url_fun.(token))
          {:ok, invite}

        error ->
          error
      end
    end
  end

  def revoke_invite(%OrganizationInvite{} = invite) do
    invite
    |> Ecto.Changeset.change(revoked_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  def accept_invite(%OrganizationInvite{} = invite, user) do
    if OrganizationInvite.active?(invite) do
      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :invite,
        Ecto.Changeset.change(invite,
          accepted_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )
      )
      |> Ecto.Multi.insert(:membership, fn _ ->
        %OrganizationMembership{
          organization_id: invite.organization_id,
          user_id: user.id,
          role: invite.role
        }
      end)
      |> Ecto.Multi.run(:workspace_memberships, fn repo, _ ->
        # Automatically assign user to all non-archived workspaces in this org
        workspaces = Workspaces.list_workspaces_for_organization(invite.organization_id)

        Enum.each(workspaces, fn ws ->
          repo.insert(
            %Fanoutpages.Workspaces.WorkspaceMembership{
              workspace_id: ws.id,
              user_id: user.id
            },
            on_conflict: :nothing
          )
        end)

        {:ok, :ok}
      end)
      |> Repo.transaction()
    else
      {:error, :invite_expired_or_invalid}
    end
  end

  def remove_member(organization_id, user_id) do
    from(m in OrganizationMembership,
      where: m.organization_id == ^organization_id and m.user_id == ^user_id and m.role != "owner"
    )
    |> Repo.delete_all()
  end

  def get_membership(organization_id, user_id) do
    Repo.get_by(OrganizationMembership,
      organization_id: organization_id,
      user_id: user_id
    )
  end

  def update_plan(organization, attrs) do
    organization
    |> Organization.plan_changeset(attrs)
    |> Repo.update()
  end
end
