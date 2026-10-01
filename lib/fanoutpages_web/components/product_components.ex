defmodule FanoutpagesWeb.ProductComponents do
  @moduledoc """
  Product-specific UI components including the Settings sub-navigation sidebar.
  """
  use Phoenix.Component
  use FanoutpagesWeb, :verified_routes

  @doc """
  Renders the 2-column settings sub-navigation sidebar matching TenderFolder.
  """
  attr :active, :atom, required: true
  attr :current_scope, :any, default: nil

  def settings_nav(assigns) do
    ~H"""
    <nav class="menu gap-1 p-0" aria-label="Settings sections">
      <.settings_nav_item
        href={~p"/settings/account"}
        icon="hero-user-circle"
        label="Account"
        active={@active == :account}
      />
      <.settings_nav_item
        href={~p"/settings/organization"}
        icon="hero-building-office"
        label="Organization"
        active={@active == :organization}
      />
      <.settings_nav_item
        href={~p"/settings/team"}
        icon="hero-users"
        label="Team & Members"
        active={@active == :team}
      />
      <.settings_nav_item
        href={~p"/settings/billing"}
        icon="hero-credit-card"
        label="Billing & Quota"
        active={@active == :billing}
      />
      <.settings_nav_item
        href={~p"/settings/automation"}
        icon="hero-bolt"
        label="API & Automation"
        active={@active == :automation}
      />
    </nav>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, required: true

  defp settings_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center gap-2.5 rounded-lg px-3 py-2 text-xs font-medium transition-colors",
        if(@active,
          do: "bg-base-300/60 font-semibold text-base-content",
          else: "text-base-content/60 hover:bg-base-200 hover:text-base-content"
        )
      ]}
    >
      <FanoutpagesWeb.CoreComponents.icon name={@icon} class="size-4 shrink-0" />
      <span>{@label}</span>
    </.link>
    """
  end
end
