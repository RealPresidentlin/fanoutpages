defmodule Fanoutpages.Billing.PlanConfig do
  @moduledoc """
  Canonical plan definitions, quotas, add-ons and Polar product mapping for FanoutPages.
  """

  @plans %{
    "starter" => %{
      id: "starter",
      name: "Starter",
      audience: :business,
      price_monthly_cents: 2_900,
      price_annual_effective_cents: 2_400,
      description:
        "For creators and individual businesses managing their own social media presence.",
      recommended: false,
      quotas: %{
        max_workspaces: 1,
        max_social_accounts: 10,
        max_humans: :unlimited,
        agents_per_human: :unlimited,
        max_agents: :unlimited,
        storage_bytes: 5_000_000_000
      },
      history_retention_days: 30,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        approvals: true,
        analytics: false
      }
    },
    "business" => %{
      id: "business",
      name: "Business",
      audience: :business,
      price_monthly_cents: 5_900,
      price_annual_effective_cents: 4_900,
      description:
        "For growing single-brand teams scaling social publishing with their AI teammates.",
      recommended: true,
      quotas: %{
        max_workspaces: 1,
        max_social_accounts: 25,
        max_humans: :unlimited,
        agents_per_human: :unlimited,
        max_agents: :unlimited,
        storage_bytes: 5_000_000_000
      },
      history_retention_days: 90,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        approvals: true,
        analytics: false
      }
    },
    "core" => %{
      id: "core",
      name: "Core",
      audience: :agency,
      price_monthly_cents: 11_900,
      price_annual_effective_cents: 9_900,
      description:
        "Manage multiple brands or clients with your human and AI teammates in one system.",
      recommended: false,
      quotas: %{
        max_workspaces: 3,
        max_social_accounts: 45,
        max_humans: :unlimited,
        agents_per_human: :unlimited,
        max_agents: :unlimited,
        storage_bytes: 5_000_000_000
      },
      history_retention_days: 90,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        approvals: true,
        analytics: false
      }
    },
    "scale" => %{
      id: "scale",
      name: "Scale",
      audience: :agency,
      price_monthly_cents: 24_900,
      price_annual_effective_cents: 19_900,
      description: "Manage multiple brands and client accounts with high publishing capacity.",
      recommended: true,
      quotas: %{
        max_workspaces: 10,
        max_social_accounts: 150,
        max_humans: :unlimited,
        agents_per_human: :unlimited,
        max_agents: :unlimited,
        storage_bytes: 5_000_000_000
      },
      history_retention_days: 365,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        approvals: true,
        analytics: false
      }
    },
    "pro" => %{
      id: "pro",
      name: "Pro",
      audience: :agency,
      price_monthly_cents: 44_900,
      price_annual_effective_cents: 35_900,
      description: "For agencies and large organizations managing high-volume publishing.",
      recommended: false,
      quotas: %{
        max_workspaces: 25,
        max_social_accounts: 375,
        max_humans: :unlimited,
        agents_per_human: :unlimited,
        max_agents: :unlimited,
        storage_bytes: 5_000_000_000
      },
      history_retention_days: 730,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        approvals: true,
        analytics: false
      }
    }
  }

  @plan_order ~w(starter business core scale pro)

  def all, do: @plans

  def ordered, do: Enum.map(@plan_order, &Map.fetch!(@plans, &1))

  def for_audience(:business) do
    ~w(starter business) |> Enum.map(&Map.fetch!(@plans, &1))
  end

  def for_audience(:agency) do
    ~w(core scale pro) |> Enum.map(&Map.fetch!(@plans, &1))
  end

  def for_audience(_), do: ordered()

  @add_ons [
    %{
      id: "workspace",
      name: "Additional Workspace",
      price_monthly_cents: 3_900,
      description: "+1 brand or client workspace"
    },
    %{
      id: "social_accounts",
      name: "Social Accounts Bundle",
      price_monthly_cents: 2_900,
      description: "+30 connected social profiles"
    }
  ]

  def add_ons, do: @add_ons

  def get(plan) when is_binary(plan), do: Map.get(@plans, String.downcase(plan))
  def get(_plan), do: nil

  def storage_bytes(plan) do
    case get(plan) do
      %{quotas: %{storage_bytes: bytes}} -> bytes
      _ -> 5_000_000_000
    end
  end

  def available_for_account_type?(plan, "business") when plan in ~w(starter business), do: true
  def available_for_account_type?(plan, "agency") when plan in ~w(core scale pro), do: true
  def available_for_account_type?(_plan, _account_type), do: false

  def entitlements(plan) when is_binary(plan) do
    with %{} = config <- get(plan) do
      Map.take(config, [:quotas, :history_retention_days, :features])
    end
  end

  def entitlements(_plan), do: nil

  def limits(plan) do
    case entitlements(plan) do
      %{quotas: quotas, features: features} -> Map.merge(quotas, features)
      nil -> locked_limits()
    end
  end

  def locked_limits do
    %{
      max_workspaces: 0,
      max_social_accounts: 0,
      max_humans: 0,
      agents_per_human: 0,
      max_agents: 0,
      unlimited_posts: false,
      api_access: false,
      mcp_access: false,
      approvals: false,
      analytics: false
    }
  end

  def product_id("starter", :monthly),
    do: Application.get_env(:fanoutpages, :polar_starter_monthly_product_id)

  def product_id("starter", :annual),
    do: Application.get_env(:fanoutpages, :polar_starter_annual_product_id)

  def product_id("business", :monthly),
    do: Application.get_env(:fanoutpages, :polar_business_monthly_product_id)

  def product_id("business", :annual),
    do: Application.get_env(:fanoutpages, :polar_business_annual_product_id)

  def product_id("core", :monthly),
    do: Application.get_env(:fanoutpages, :polar_core_monthly_product_id)

  def product_id("core", :annual),
    do: Application.get_env(:fanoutpages, :polar_core_annual_product_id)

  def product_id("scale", :monthly),
    do: Application.get_env(:fanoutpages, :polar_scale_monthly_product_id)

  def product_id("scale", :annual),
    do: Application.get_env(:fanoutpages, :polar_scale_annual_product_id)

  def product_id("pro", :monthly),
    do: Application.get_env(:fanoutpages, :polar_pro_monthly_product_id)

  def product_id("pro", :annual),
    do: Application.get_env(:fanoutpages, :polar_pro_annual_product_id)

  def product_id(_plan, _interval), do: nil

  def product_id(plan), do: product_id(plan, :monthly)

  def plan_from_product_id(product_id) when is_binary(product_id) do
    Enum.find_value(@plan_order, fn plan ->
      if product_id(plan, :monthly) == product_id or product_id(plan, :annual) == product_id do
        plan
      end
    end)
  end

  def plan_from_product_id(_product_id), do: nil
end
