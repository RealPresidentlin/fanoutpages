defmodule Fanoutpages.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :account_type, :string, default: "agency"
    field :plan, :string, default: "core"
    field :subscription_status, :string, default: "trialing"
    field :started_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :polar_customer_id, :string
    field :polar_subscription_id, :string
    field :polar_product_id, :string
    field :polar_price_id, :string
    field :polar_checkout_id, :string

    belongs_to :created_by_user, Fanoutpages.Accounts.User
    has_many :memberships, Fanoutpages.Organizations.OrganizationMembership
    has_many :users, through: [:memberships, :user]
    has_many :workspaces, Fanoutpages.Workspaces.Workspace
    has_many :payment_subscriptions, Fanoutpages.Payments.OrganizationPaymentSubscription
    has_many :payment_transactions, Fanoutpages.Payments.OrganizationPaymentTransaction

    timestamps(type: :utc_datetime)
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :slug, :account_type])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:slug, min: 2, max: 80)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
    |> validate_inclusion(:account_type, ~w(business agency))
    |> unique_constraint(:slug)
  end

  def plan_changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :plan,
      :subscription_status,
      :started_at,
      :ends_at,
      :polar_customer_id,
      :polar_subscription_id,
      :polar_product_id,
      :polar_price_id,
      :polar_checkout_id
    ])
    |> validate_inclusion(:plan, ["core", "scale", "pro", "enterprise"])
    |> validate_inclusion(:subscription_status, [
      "trialing",
      "active",
      "canceled",
      "past_due",
      "expired"
    ])
  end
end
