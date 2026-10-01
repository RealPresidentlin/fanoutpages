defmodule Fanoutpages.Workspaces do
  @moduledoc """
  The Workspaces context for brand and client environments within an organization.
  """

  import Ecto.Query, warn: false
  alias Fanoutpages.Repo
  alias Fanoutpages.Workspaces.{Workspace, WorkspaceMembership}
  alias Fanoutpages.Organizations.{Organization, OrganizationMembership}
  alias Fanoutpages.Access.Scope

  def get_workspace(id) when is_binary(id), do: Repo.get(Workspace, id)
  def get_workspace!(id), do: Repo.get!(Workspace, id)

  def get_workspace_by_slug(slug) when is_binary(slug), do: Repo.get_by(Workspace, slug: slug)

  def list_workspaces_for_organization(org_id) do
    from(w in Workspace,
      where: w.organization_id == ^org_id and is_nil(w.archived_at),
      order_by: [asc: w.name]
    )
    |> Repo.all()
  end

  def count_workspaces_for_organization(org_id) do
    from(w in Workspace,
      where: w.organization_id == ^org_id and is_nil(w.archived_at)
    )
    |> Repo.aggregate(:count, :id)
  end

  def build_slug(organization, attrs_or_name) do
    name =
      cond do
        is_binary(attrs_or_name) ->
          attrs_or_name

        is_map(attrs_or_name) ->
          Map.get(attrs_or_name, "name") || Map.get(attrs_or_name, :name) || "brand"

        true ->
          "brand"
      end

    normalized =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/[\s-]+/, "-")
      |> String.trim("-")

    normalized = if normalized == "", do: "brand", else: normalized
    suffix = Ecto.UUID.generate() |> String.slice(0, 6)
    org_slug = (organization && organization.slug) || "brand"
    "#{org_slug}-#{normalized}-#{suffix}"
  end

  def create_workspace(organization, attrs, user \\ nil) do
    attrs =
      if is_map(attrs) and (is_nil(Map.get(attrs, "slug")) or Map.get(attrs, "slug") == "") and
           (is_nil(Map.get(attrs, :slug)) or Map.get(attrs, :slug) == "") do
        Map.put(attrs, "slug", build_slug(organization, attrs))
      else
        attrs
      end

    %Workspace{organization_id: organization.id}
    |> Workspace.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:organization, organization)
    |> Repo.insert()
    |> case do
      {:ok, workspace} ->
        if user do
          Repo.insert!(%WorkspaceMembership{workspace_id: workspace.id, user_id: user.id})
        end

        {:ok, workspace}

      error ->
        error
    end
  end

  def change_workspace(%Workspace{} = workspace, attrs \\ %{}) do
    Workspace.changeset(workspace, attrs)
  end

  @doc """
  Computes the active Scope for the current user and optional workspace_slug.
  """
  def default_scope(user, requested_workspace_slug \\ nil)

  def default_scope(nil, _), do: nil

  def default_scope(user, requested_workspace_slug) do
    # 1. Find user's organization memberships with preloaded organization
    memberships =
      from(m in OrganizationMembership,
        where: m.user_id == ^user.id,
        preload: [:organization],
        order_by: [asc: m.inserted_at]
      )
      |> Repo.all()

    case memberships do
      [] ->
        nil

      [first_membership | _] ->
        # If requested_workspace_slug is given, try finding matching workspace across user's orgs
        workspace_and_org =
          if is_binary(requested_workspace_slug) and requested_workspace_slug != "" do
            from(w in Workspace,
              join: o in Organization,
              on: o.id == w.organization_id,
              join: om in OrganizationMembership,
              on: om.organization_id == o.id and om.user_id == ^user.id,
              where: w.slug == ^requested_workspace_slug and is_nil(w.archived_at),
              select: {w, om, o}
            )
            |> Repo.one()
          end

        case workspace_and_org do
          {workspace, org_membership, organization} ->
            workspace_membership =
              Repo.get_by(WorkspaceMembership,
                workspace_id: workspace.id,
                user_id: user.id
              )

            build_scope(user, organization, org_membership, workspace, workspace_membership)

          nil ->
            # Fallback to the first organization and its first workspace (if any)
            target_membership = first_membership
            org = target_membership.organization

            workspace =
              from(w in Workspace,
                where: w.organization_id == ^org.id and is_nil(w.archived_at),
                order_by: [asc: w.inserted_at],
                limit: 1
              )
              |> Repo.one()

            workspace_membership =
              if workspace do
                Repo.get_by(WorkspaceMembership,
                  workspace_id: workspace.id,
                  user_id: user.id
                )
              end

            build_scope(user, org, target_membership, workspace, workspace_membership)
        end
    end
  end

  def get_accessible_by_slug(user, slug) when is_binary(slug) do
    with %Workspace{} = workspace <-
           Workspace
           |> where([w], w.slug == ^slug and is_nil(w.archived_at))
           |> preload(:organization)
           |> Repo.one(),
         %OrganizationMembership{} = org_membership <-
           Repo.get_by(OrganizationMembership,
             organization_id: workspace.organization_id,
             user_id: user.id
           ) do
      workspace_membership =
        Repo.get_by(WorkspaceMembership,
          workspace_id: workspace.id,
          user_id: user.id
        )

      build_scope(user, workspace.organization, org_membership, workspace, workspace_membership)
    else
      _ -> nil
    end
  end

  defp build_scope(user, organization, org_membership, workspace, workspace_membership) do
    org =
      case organization do
        %Organization{} = loaded_org -> loaded_org
        _ -> nil
      end

    membership =
      case org_membership do
        %OrganizationMembership{} = m when not is_nil(org) -> %{m | organization: org}
        m -> m
      end

    ws =
      case workspace do
        %Workspace{} = w when not is_nil(org) -> %{w | organization: org}
        w -> w
      end

    %Scope{
      user: user,
      organization: org,
      organization_membership: membership,
      workspace: ws,
      workspace_membership: workspace_membership
    }
  end
end
