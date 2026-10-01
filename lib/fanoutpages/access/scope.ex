defmodule Fanoutpages.Access.Scope do
  @moduledoc """
  Encapsulates the authorization and tenancy scope of the current request/LiveView.
  """

  defstruct [
    :user,
    :organization,
    :organization_membership,
    :workspace,
    :workspace_membership
  ]

  def organization_admin?(%{organization_membership: %{role: role}}),
    do: role in ["owner", "admin"]

  def organization_admin?(_), do: false

  def organization_owner?(%{organization_membership: %{role: "owner"}}), do: true
  def organization_owner?(_), do: false

  def agency?(%{organization: %Fanoutpages.Organizations.Organization{account_type: "agency"}}),
    do: true

  def agency?(_), do: false

  def business?(%{
        organization: %Fanoutpages.Organizations.Organization{account_type: "business"}
      }),
      do: true

  def business?(%{organization: %Fanoutpages.Organizations.Organization{account_type: "agency"}}),
    do: false

  def business?(%{organization: %Fanoutpages.Organizations.Organization{}}), do: true
  def business?(_), do: false
end
