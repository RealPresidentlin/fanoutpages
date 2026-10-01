defmodule FanoutpagesWeb.DashboardLive do
  use FanoutpagesWeb, :live_view

  alias Fanoutpages.Billing.PlanConfig
  alias Fanoutpages.Workspaces

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active_nav={:dashboard}>
      <div id="dashboard-page" class="space-y-10 pb-20">
        <!-- Header -->
        <header class="space-y-6 border-b border-base-200 pb-8">
          <nav
            aria-label="Breadcrumb"
            class="flex items-center gap-2 text-xs font-medium text-base-content/50"
          >
            <span>{(@current_scope.workspace && @current_scope.workspace.name) ||
              @current_scope.organization.name}</span>
            <span>/</span>
            <span class="text-base-content font-semibold">Dashboard</span>
          </nav>

          <div class="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
            <div class="space-y-2 max-w-2xl">
              <div class="flex items-center gap-3">
                <h1 class="text-3xl font-semibold tracking-tight sm:text-4xl text-base-content">
                  <%= if Fanoutpages.Access.Scope.agency?(@current_scope) do %>
                    {(@current_scope.workspace && @current_scope.workspace.name) ||
                      "Operations Overview"}
                  <% else %>
                    General Overview
                  <% end %>
                </h1>
                <span
                  :if={Fanoutpages.Access.Scope.agency?(@current_scope)}
                  class="badge badge-primary badge-sm uppercase font-bold tracking-wider"
                >
                  Active Brand
                </span>
              </div>
              <p class="text-sm text-base-content/60 leading-relaxed">
                Autonomous social media queue, fleet capacity, and cross-channel performance for {@current_scope.organization.name}.
              </p>
            </div>

            <div class="flex flex-wrap items-center gap-3">
              <%= if Fanoutpages.Access.Scope.agency?(@current_scope) do %>
                <.link
                  navigate={~p"/workspaces"}
                  class="btn btn-sm btn-ghost border border-base-200 rounded-lg text-xs font-medium hover:bg-base-200/50"
                >
                  <.icon name="hero-building-office-2" class="size-3.5" /> All Brands
                </.link>

                <.link
                  navigate={~p"/workspaces/new"}
                  class="btn btn-sm btn-ghost border border-base-200 rounded-lg text-xs font-medium hover:bg-base-200/50"
                >
                  <.icon name="hero-plus" class="size-3.5" /> Add Brand
                </.link>
              <% end %>

              <.link
                navigate={~p"/pricing"}
                class="btn btn-sm btn-primary rounded-lg font-medium text-xs px-5 shadow-none"
              >
                <.icon name="hero-bolt" class="size-3.5" /> Scale Fleet
              </.link>
            </div>
          </div>
        </header>

        <!-- Inline Metric Strip -->
        <section id="dashboard-metrics" class="border-b border-base-200 pb-8">
          <div class="grid grid-cols-2 gap-6 sm:grid-cols-4 lg:divide-x lg:divide-base-200">
            <div class="space-y-1">
              <span class="text-xs text-base-content/50 font-medium">Connected Accounts</span>
              <div class="flex items-baseline gap-2">
                <span class="text-2xl font-semibold tracking-tight text-base-content">
                  0
                </span>
                <span class="text-xs text-base-content/40">/ {@limits.max_social_accounts} allowed</span>
              </div>
              <p class="text-[11px] text-base-content/50">X, LinkedIn, Threads, Instagram</p>
            </div>

            <div class="space-y-1 lg:pl-6">
              <span class="text-xs text-base-content/50 font-medium">Autonomous Agents</span>
              <div class="flex items-baseline gap-2">
                <span class="text-2xl font-semibold tracking-tight text-base-content">
                  0
                </span>
                <span class="text-xs text-base-content/40">/ {@limits.max_agents} agents</span>
              </div>

            </div>

            <div class="space-y-1 lg:pl-6">
              <span class="text-xs text-base-content/50 font-medium">
                {if Fanoutpages.Access.Scope.agency?(@current_scope),
                  do: "Active Brands",
                  else: "Workspace"}
              </span>
              <div class="flex items-baseline gap-2">
                <span class="text-2xl font-semibold tracking-tight text-base-content">
                  {@workspace_count}
                </span>
                <span class="text-xs text-base-content/40">
                  / {if Fanoutpages.Access.Scope.agency?(@current_scope),
                    do: "#{@limits.max_workspaces} workspaces",
                    else: "1 workspace"}
                </span>
              </div>
              <p class="text-[11px] text-base-content/50">
                {if Fanoutpages.Access.Scope.agency?(@current_scope),
                  do: "Isolated client environments",
                  else: "Primary business workspace"}
              </p>
            </div>

            <div class="space-y-1 lg:pl-6">
              <span class="text-xs text-base-content/50 font-medium">Dispatch Queue</span>
              <div class="flex items-baseline gap-2">
                <span class="text-2xl font-semibold tracking-tight text-success">
                  0
                </span>
                <span class="text-xs text-base-content/40">scheduled posts</span>
              </div>
              <p class="text-[11px] text-base-content/50">Human approval gate enabled</p>
            </div>
          </div>
        </section>

        <!-- Main Cards Grid -->
        <div class="grid gap-6 md:grid-cols-2">
          <div class="card rounded-2xl border border-base-300 bg-base-100 p-6 shadow-sm">
            <div class="flex items-center justify-between pb-4 border-b border-base-200">
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
                  <.icon name="hero-sparkles" class="size-5" />
                </div>
                <div>
                  <h3 class="font-bold text-base text-base-content">Get Started with FanoutPages</h3>
                  <p class="text-xs text-base-content/60">
                    Configure your social channels and AI agents
                  </p>
                </div>
              </div>
            </div>

            <div class="mt-4 space-y-3">
              <div class="flex items-center justify-between p-3 rounded-xl bg-base-200/50 border border-base-200">
                <div class="flex items-center gap-3">
                  <.icon name="hero-check-circle" class="size-5 text-base-content/30" />
                  <div>
                    <p class="text-xs font-semibold text-base-content">1. Connect Social Profiles</p>
                    <p class="text-[11px] text-base-content/50">
                      Link Twitter/X, LinkedIn, Threads, or Instagram
                    </p>
                  </div>
                </div>
                <.link navigate={~p"/workspaces"} class="btn btn-xs btn-ghost border border-base-300">Configure</.link>
              </div>

              <div class="flex items-center justify-between p-3 rounded-xl bg-base-200/50 border border-base-200">
                <div class="flex items-center gap-3">
                  <.icon name="hero-check-circle" class="size-5 text-base-content/30" />
                  <div>
                    <p class="text-xs font-semibold text-base-content">2. Configure Agent Webhooks</p>
                    <p class="text-[11px] text-base-content/50">
                      Model Context Protocol (MCP) or REST endpoints
                    </p>
                  </div>
                </div>
                <.link
                  navigate={~p"/settings/profile"}
                  class="btn btn-xs btn-ghost border border-base-300"
                >API keys</.link>
              </div>

              <div class="flex items-center justify-between p-3 rounded-xl bg-base-200/50 border border-base-200">
                <div class="flex items-center gap-3">
                  <.icon name="hero-check-circle" class="size-5 text-base-content/30" />
                  <div>
                    <p class="text-xs font-semibold text-base-content">
                      3. Invite Team Collaborators
                    </p>
                    <p class="text-[11px] text-base-content/50">Assign reviewer and admin roles</p>
                  </div>
                </div>
                <.link
                  navigate={~p"/settings/team"}
                  class="btn btn-xs btn-ghost border border-base-300"
                >Invite</.link>
              </div>
            </div>
          </div>

          <div class="card rounded-2xl border border-base-300 bg-base-100 p-6 shadow-sm">
            <div class="flex items-center justify-between pb-4 border-b border-base-200">
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-xl bg-secondary/10 text-secondary">
                  <.icon name="hero-bolt" class="size-5" />
                </div>
                <div>
                  <h3 class="font-bold text-base text-base-content">Fleet Capacity & Plan</h3>
                  <p class="text-xs text-base-content/60">Current organization quota</p>
                </div>
              </div>
              <span class="badge badge-primary badge-sm font-bold uppercase">
                {@current_scope.organization.plan}
              </span>
            </div>

            <div class="mt-5 space-y-4">
              <div>
                <div class="flex justify-between text-xs font-medium mb-1">
                  <span class="text-base-content/60">Workspaces</span>
                  <span class="font-bold">{@workspace_count} / {@limits.max_workspaces}</span>
                </div>
                <div class="h-2 w-full rounded-full bg-base-200 overflow-hidden">
                  <div
                    class="h-full bg-primary transition-all"
                    style={"width: #{min(100, (@workspace_count / max(1, @limits.max_workspaces)) * 100)}%"}
                  >
                  </div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-xs font-medium mb-1">
                  <span class="text-base-content/60">Connected Social Profiles</span>
                  <span class="font-bold">0 / {@limits.max_social_accounts}</span>
                </div>
                <div class="h-2 w-full rounded-full bg-base-200 overflow-hidden">
                  <div class="h-full bg-secondary" style="width: 0%"></div>
                </div>
              </div>

              <div class="pt-2">
                <.link
                  navigate={~p"/pricing"}
                  class="btn btn-primary btn-sm w-full font-semibold rounded-xl"
                >
                  Manage Capacity & Upgrade
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    plan = (scope && scope.organization && Map.get(scope.organization, :plan)) || "core"
    limits = PlanConfig.limits(plan)
    org_id = scope && scope.organization && Map.get(scope.organization, :id)
    workspace_count = if org_id, do: Workspaces.count_workspaces_for_organization(org_id), else: 0

    {:ok,
     socket
     |> assign(:limits, limits)
     |> assign(:workspace_count, workspace_count)}
  end
end
