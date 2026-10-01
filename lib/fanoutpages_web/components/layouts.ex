defmodule FanoutpagesWeb.Layouts do
  @moduledoc """
  Layout components for Fanout Pages.
  """
  use FanoutpagesWeb, :html

  embed_templates "layouts/*"

  @doc """
  Main app layout wrapping LiveView pages with a responsive sidebar,
  active workspace/brand switcher, user profile menu, and flash group.
  """
  attr :flash, :map, required: true
  attr :current_scope, :any, default: nil
  attr :current_user, :any, default: nil
  attr :current_organization, :any, default: nil
  attr :current_workspace, :any, default: nil
  attr :current_membership, :any, default: nil
  attr :shell, :atom, default: nil, values: [:product, :plain, nil]
  attr :full_width, :boolean, default: false
  attr :active_nav, :atom, default: :dashboard
  slot :inner_block, required: true

  def app(assigns) do
    scope = assigns[:current_scope]
    user = (scope && Map.get(scope, :user)) || assigns[:current_user]
    organization = (scope && Map.get(scope, :organization)) || assigns[:current_organization]
    workspace = (scope && Map.get(scope, :workspace)) || assigns[:current_workspace]

    membership =
      (scope && (Map.get(scope, :organization_membership) || Map.get(scope, :membership))) ||
        assigns[:current_membership]

    accessible_workspaces =
      if organization do
        Fanoutpages.Workspaces.list_workspaces_for_organization(organization.id)
      else
        []
      end

    shell =
      cond do
        assigns[:shell] -> assigns[:shell]
        user != nil -> :product
        true -> :plain
      end

    plan_active? =
      is_nil(organization) ||
        Map.get(organization, :subscription_status) in ["active", "trialing"]

    assigns =
      assigns
      |> assign(:current_user, user)
      |> assign(:current_organization, organization)
      |> assign(:current_workspace, workspace)
      |> assign(:current_membership, membership)
      |> assign(:accessible_workspaces, accessible_workspaces)
      |> assign(:shell, shell)
      |> assign(:plan_active?, plan_active?)

    ~H"""
    <%= if @shell == :product do %>
      <div id="product-shell" class="drawer min-h-screen bg-base-200 lg:drawer-open">
        <input id="product-drawer" type="checkbox" class="drawer-toggle" />
        <div class="drawer-content flex min-w-0 flex-col">
          <header class="sticky top-0 z-30 flex h-16 items-center border-b border-base-300 bg-base-100/95 px-4 backdrop-blur sm:px-6">
            <label
              for="product-drawer"
              class="btn btn-ghost btn-square mr-3 text-base-content/60 lg:hidden"
              aria-label="Open navigation"
            >
              <.icon name="hero-bars-3" class="size-5" />
            </label>

            <!-- Search or Breadcrumb -->
            <div class="hidden max-w-lg flex-1 items-center gap-3 rounded-xl border border-base-300 bg-base-200 px-4 py-2 text-sm text-base-content/45 transition hover:border-base-300 hover:bg-base-100 md:flex">
              <.icon name="hero-magnifying-glass" class="size-4" />
              <span>Search brands, scheduled posts, or fleet logs…</span>
            </div>

            <div class="ml-auto flex items-center gap-2 sm:gap-3">
              <button
                id="notifications-button"
                type="button"
                class="btn btn-ghost btn-circle relative text-base-content/60 hover:text-base-content"
                aria-label="Notifications"
              >
                <.icon name="hero-bell" class="size-5" />
                <span class="absolute right-2 top-2 size-2 rounded-full border-2 border-base-100 bg-primary"></span>
              </button>

              <div class="hidden h-8 w-px bg-base-300 sm:block"></div>

              <div class="dropdown dropdown-end">
                <button
                  id="account-menu-button"
                  type="button"
                  tabindex="0"
                  class="btn btn-ghost h-auto min-h-0 rounded-full p-1 font-normal"
                >
                  <div class="hidden text-right sm:block">
                    <p class="text-sm font-bold leading-none text-base-content">
                      {user_name(@current_user)}
                    </p>
                    <p class="mt-1 text-[10px] font-black uppercase tracking-widest text-base-content/45">
                      {membership_role(@current_membership)}
                    </p>
                  </div>
                  <div class="flex size-9 items-center justify-center rounded-full border border-base-300 bg-base-200 font-bold text-base-content/60">
                    {user_initial(@current_user)}
                  </div>
                </button>
                <ul
                  tabindex="0"
                  class="dropdown-content menu z-40 mt-3 w-52 rounded-xl border border-base-300 bg-base-100 p-2 shadow-xl"
                >
                  <li>
                    <.link navigate={~p"/settings/profile"}>
                      <.icon name="hero-user-circle" class="size-4" /> Account settings
                    </.link>
                  </li>
                  <li>
                    <.link navigate={~p"/settings/team"}>
                      <.icon name="hero-users" class="size-4" /> Team settings
                    </.link>
                  </li>
                  <li>
                    <.link navigate={~p"/billing"}>
                      <.icon name="hero-credit-card" class="size-4" /> Billing & Usage
                    </.link>
                  </li>
                  <div class="divider my-1"></div>
                  <li>
                    <.link href={~p"/users/log_out"} method="delete" class="text-error">
                      <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Log out
                    </.link>
                  </li>
                </ul>
              </div>
            </div>
          </header>

          <div
            :if={!@plan_active?}
            id="expired-plan-banner"
            role="alert"
            class="alert alert-warning alert-soft alert-vertical rounded-none border-x-0 sm:alert-horizontal"
          >
            <.icon name="hero-exclamation-triangle" class="size-6 shrink-0" />
            <div>
              <h3 class="font-bold">Subscription attention required</h3>
              <p class="text-xs leading-5 opacity-75">
                <%= if can_manage_billing?(@current_membership) do %>
                  Your organization plan is inactive. Upgrade or renew to enable autonomous social scheduling.
                <% else %>
                  The organization plan is inactive. Ask an owner or admin to review billing.
                <% end %>
              </p>
            </div>
            <.link
              :if={can_manage_billing?(@current_membership)}
              navigate={~p"/pricing"}
              class="btn btn-warning btn-sm shrink-0"
            >
              Review Plans <.icon name="hero-arrow-right" class="size-4" />
            </.link>
          </div>

          <main id="product-content" class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class={if(@full_width, do: "w-full", else: "mx-auto w-full max-w-7xl")}>
              {render_slot(@inner_block)}
            </div>
          </main>
        </div>

        <!-- Sidebar Navigation Drawer -->
        <div class="drawer-side z-40">
          <label for="product-drawer" class="drawer-overlay" aria-label="Close navigation"></label>
          <aside class="flex min-h-full w-64 flex-col border-r border-base-300 bg-base-100">
            <!-- App Logo / Name -->
            <div class="flex h-16 items-center gap-3 px-6">
              <div class="flex size-9 items-center justify-center rounded-xl bg-primary shadow-sm shadow-primary/20">
                <.icon name="hero-megaphone" class="size-5 text-primary-content" />
              </div>
              <span class="text-xl font-extrabold tracking-tight text-base-content">
                Fanout<span class="text-primary">Pages</span>
              </span>
            </div>

            <!-- Navigation Menu -->
            <nav id="product-navigation" class="menu flex-1 gap-1 px-4 py-3">
              <.nav_item
                href={workspace_path(@current_workspace, :dashboard)}
                icon="hero-squares-2x2"
                label="Dashboard"
                active={@active_nav == :dashboard}
              />
              <.nav_item
                :if={Fanoutpages.Access.Scope.agency?(@current_scope)}
                href={~p"/workspaces"}
                icon="hero-building-office-2"
                label="Brands & Clients"
                active={@active_nav == :workspaces}
              />
              <.nav_item
                href={~p"/settings/team"}
                icon="hero-users"
                label="Team & Members"
                active={@active_nav == :team}
              />
              <.nav_item
                href={~p"/pricing"}
                icon="hero-bolt"
                label="Pricing & Plans"
                active={@active_nav == :pricing}
              />
              <.nav_item
                href={~p"/billing"}
                icon="hero-credit-card"
                label="Billing & Capacity"
                active={@active_nav == :billing}
              />
              <.nav_item
                href={~p"/settings/profile"}
                icon="hero-cog-6-tooth"
                label="Settings"
                active={@active_nav == :settings}
              />
            </nav>

            <!-- Bottom Workspace / Brand Switcher (Agency) or Static Tenant Indicator (Business) -->
            <div class="border-t border-base-200 p-4">
              <%= if Fanoutpages.Access.Scope.agency?(@current_scope) do %>
                <div class="dropdown dropdown-top w-full">
                  <button
                    id="workspace-switcher"
                    type="button"
                    tabindex="0"
                    class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition hover:bg-base-200"
                  >
                    <div class="flex size-9 items-center justify-center rounded-full bg-base-200 font-bold text-xs text-primary">
                      {brand_initial(@current_workspace || @current_organization)}
                    </div>
                    <span class="min-w-0 flex-1">
                      <div>
                        <p class="truncate text-sm font-bold text-base-content">
                          {organization_name(@current_workspace || @current_organization)}
                        </p>
                        <p class="text-[10px] font-black uppercase tracking-widest text-base-content/45">
                          {organization_plan(@current_organization)}
                        </p>
                      </div>
                    </span>
                    <.icon name="hero-chevron-up-down" class="size-4 text-base-content/40" />
                  </button>
                  <ul
                    tabindex="0"
                    class="dropdown-content menu z-50 mb-2 w-full rounded-xl border border-base-300 bg-base-100 p-2 shadow-xl"
                  >
                    <li class="menu-title text-[10px] uppercase font-bold tracking-wider text-base-content/50 px-2 py-1">
                      Brands & Workspaces
                    </li>
                    <li :for={workspace <- @accessible_workspaces}>
                      <.link href={~p"/workspaces/#{workspace.slug}/switch"}>
                        <.icon name="hero-sparkles" class="size-4" />
                        <span class="truncate">{workspace.name}</span>
                      </.link>
                    </li>
                    <li>
                      <.link navigate={~p"/workspaces"}>
                        <.icon name="hero-folder" class="size-4" /> Manage All
                      </.link>
                    </li>
                  </ul>
                </div>
              <% else %>
                <div class="flex w-full items-center gap-3 rounded-xl px-3 py-2 bg-base-200/50">
                  <div class="flex size-9 items-center justify-center rounded-full bg-primary/10 font-bold text-xs text-primary">
                    {brand_initial(@current_organization)}
                  </div>
                  <span class="min-w-0 flex-1">
                    <div>
                      <p class="truncate text-sm font-bold text-base-content">
                        {organization_name(@current_organization)}
                      </p>
                      <p class="text-[10px] font-black uppercase tracking-widest text-base-content/45">
                        {organization_plan(@current_organization)}
                      </p>
                    </div>
                  </span>
                </div>
              <% end %>
            </div>
          </aside>
        </div>
      </div>
    <% else %>
      <!-- Public / Auth Page Layout -->
      <div class="min-h-screen bg-base-200 flex flex-col justify-between">
        <header class="border-b border-base-300/70 bg-base-100">
          <div class="mx-auto flex h-20 max-w-7xl items-center justify-between gap-4 px-6">
            <.link navigate={~p"/"} class="flex items-center gap-3">
              <span class="flex size-10 items-center justify-center rounded-xl bg-primary shadow-lg shadow-primary/15">
                <.icon name="hero-megaphone" class="size-6 text-primary-content" />
              </span>
              <span class="text-xl font-black tracking-tight sm:text-2xl text-base-content">
                Fanout<span class="text-primary">Pages</span>
              </span>
            </.link>
            <div class="flex items-center gap-2 sm:gap-3">
              <.link
                navigate={~p"/pricing"}
                class="btn btn-ghost hidden rounded-xl text-sm text-base-content/70 hover:text-base-content sm:flex"
              >
                Pricing
              </.link>
              <%= if @current_user do %>
                <.link navigate={~p"/dashboard"} class="btn btn-primary rounded-xl">Open dashboard</.link>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="btn btn-ghost hidden rounded-xl text-base-content/70 hover:text-base-content sm:flex"
                >
                  Log out
                </.link>
              <% else %>
                <.link
                  href={~p"/users/log_in"}
                  class="btn btn-ghost hidden rounded-xl text-sm text-base-content/70 hover:text-base-content sm:flex"
                >
                  Log in
                </.link>
                <.link href={~p"/users/register"} class="btn btn-primary rounded-xl">Start free</.link>
              <% end %>
            </div>
          </div>
        </header>

        <main class={[
          "flex-1 flex flex-col",
          if(@full_width, do: "w-full", else: "container mx-auto px-4 py-8 sm:px-6 lg:px-8")
        ]}>
          <div class={if(@full_width, do: "w-full", else: "mx-auto w-full max-w-5xl space-y-4")}>
            {render_slot(@inner_block)}
          </div>
        </main>

        <footer class="border-t border-base-300/70 bg-base-100 py-6 text-center text-xs text-base-content/50">
          © {Date.utc_today().year} Fanout Pages. Autonomous social media operations for agencies and creators.
        </footer>
      </div>
    <% end %>

    <.flash_group flash={@flash} />
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :indicator, :integer, default: 0

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold transition-all",
        if(@active,
          do: "bg-base-200 text-primary",
          else: "text-base-content/70 hover:bg-base-200 hover:text-base-content"
        )
      ]}
    >
      <.icon name={@icon} class="size-5" />
      <span>{@label}</span>
      <span :if={@indicator > 0} class="badge badge-warning badge-sm ml-auto min-w-6 font-black">
        {if(@indicator > 99, do: "99+", else: @indicator)}
      </span>
    </.link>
    """
  end

  defp user_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp user_name(%{email: email}) when is_binary(email), do: email
  defp user_name(_), do: "Account"
  defp user_initial(user), do: user |> user_name() |> String.first() |> String.upcase()
  defp membership_role(%{role: role}) when is_binary(role), do: role
  defp membership_role(_), do: "Member"
  defp can_manage_billing?(%{role: role}), do: role in ["owner", "admin"]
  defp can_manage_billing?(_), do: false
  defp organization_name(%{name: name}) when is_binary(name), do: name
  defp organization_name(_), do: "Fanout Pages"

  defp organization_plan(%{plan: plan}) when is_binary(plan),
    do: "#{String.capitalize(plan)} plan"

  defp organization_plan(_), do: "Workspace"

  defp brand_initial(%{name: name}) when is_binary(name) and name != "",
    do: String.first(name) |> String.upcase()

  defp brand_initial(_), do: "F"

  defp workspace_path(nil, _section), do: ~p"/dashboard"
  defp workspace_path(%{slug: slug}, :dashboard), do: ~p"/w/#{slug}/dashboard"
  defp workspace_path(_workspace, _section), do: ~p"/dashboard"

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
