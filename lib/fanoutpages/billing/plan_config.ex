defmodule Fanoutpages.Billing.PlanConfig do
  @moduledoc """
  Canonical plan definitions, quotas, add-ons and Polar product mapping for Fanout Pages.
  """

  @plans %{
    "starter" => %{
      id: "starter",
      name: "Starter",
      audience: :business,
      price_monthly_cents: 2_900,
      price_annual_effective_cents: 2_400,
      description: "For creators and single businesses managing their own social presence.",
      recommended: false,
      quotas: %{
        max_workspaces: 1,
        max_social_accounts: 5,
        max_humans: 2,
        agents_per_human: 3,
        max_agents: 3,
        max_concurrent_agent_runs: 1
      },
      history_retention_days: 30,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        automations_webhooks: true,
        approvals: true,
        analytics: true
      }
    },
    "business" => %{
      id: "business",
      name: "Business",
      audience: :business,
      price_monthly_cents: 7_900,
      price_annual_effective_cents: 6_500,
      description:
        "For growing companies scaling their in-house social operations with AI agents.",
      recommended: true,
      quotas: %{
        max_workspaces: 1,
        max_social_accounts: 15,
        max_humans: 5,
        agents_per_human: 3,
        max_agents: 10,
        max_concurrent_agent_runs: 3
      },
      history_retention_days: 90,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        automations_webhooks: true,
        approvals: true,
        analytics: true
      }
    },
    "core" => %{
      id: "core",
      name: "Core",
      audience: :agency,
      price_monthly_cents: 11_900,
      price_annual_effective_cents: 9_900,
      description: "Run one social operation with humans and agents working together.",
      recommended: false,
      quotas: %{
        max_workspaces: 3,
        max_social_accounts: 20,
        max_humans: 10,
        agents_per_human: 3,
        max_agents: 15,
        max_concurrent_agent_runs: 3
      },
      history_retention_days: 90,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        automations_webhooks: true,
        approvals: true,
        analytics: true
      }
    },
    "scale" => %{
      id: "scale",
      name: "Scale",
      price_monthly_cents: 24_900,
      price_annual_effective_cents: 19_900,
      description: "Run multiple brands, teams, or client accounts with serious capacity.",
      recommended: true,
      quotas: %{
        max_workspaces: 10,
        max_social_accounts: 60,
        max_humans: :unlimited,
        agents_per_human: 3,
        max_agents: 50,
        max_concurrent_agent_runs: 10
      },
      history_retention_days: 365,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        automations_webhooks: true,
        approvals: true,
        analytics: true
      }
    },
    "pro" => %{
      id: "pro",
      name: "Pro",
      price_monthly_cents: 44_900,
      price_annual_effective_cents: 35_900,
      description: "For agencies and large operations managing fleet-scale publishing.",
      recommended: false,
      quotas: %{
        max_workspaces: 25,
        max_social_accounts: 150,
        max_humans: :unlimited,
        agents_per_human: 3,
        max_agents: 125,
        max_concurrent_agent_runs: 25
      },
      history_retention_days: 730,
      features: %{
        unlimited_posts: true,
        api_access: true,
        mcp_access: true,
        automations_webhooks: true,
        approvals: true,
        analytics: true
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
      description: "+1 brand or client environment"
    },
    %{
      id: "social_accounts",
      name: "Social Accounts Bundle",
      price_monthly_cents: 2_900,
      description: "+25 connected social profiles"
    },
    %{
      id: "agents",
      name: "Autonomous Agents Bundle",
      price_monthly_cents: 7_900,
      description: "+10 active AI agents"
    },
    %{
      id: "concurrency",
      name: "Concurrency Expansion",
      price_monthly_cents: 4_900,
      description: "+5 concurrent agent runs"
    }
  ]

  def add_ons, do: @add_ons

  def get(plan) when is_binary(plan), do: Map.get(@plans, String.downcase(plan))
  def get(_plan), do: nil

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
      max_concurrent_agent_runs: 0,
      unlimited_posts: false,
      api_access: false,
      mcp_access: false,
      automations_webhooks: false,
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
