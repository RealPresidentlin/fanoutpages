defmodule FanoutpagesWeb.Router do
  use FanoutpagesWeb, :router

  import FanoutpagesWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FanoutpagesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_current_organization
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", FanoutpagesWeb do
    pipe_through :api

    post "/polar/webhook", PolarWebhookController, :create
  end

  # Public and unauthenticated routes
  scope "/", FanoutpagesWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :public_or_authenticated,
      on_mount: [{FanoutpagesWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive, :index
      live "/pricing", PricingLive, :index
      live "/invites/:token", InviteLive.Accept, :edit
    end
  end

  # Routes for unauthenticated users only
  scope "/", FanoutpagesWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    post "/users/log_in", UserSessionController, :create

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{FanoutpagesWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end
  end

  # Authenticated app routes
  scope "/", FanoutpagesWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/dashboard", WorkspaceController, :index
    get "/workspaces/:slug/switch", WorkspaceSwitchController, :switch
    get "/users/settings/confirm_email/:token", UserConfirmationController, :update_email
    post "/billing/checkout", BillingCheckoutController, :create
    post "/billing/portal", BillingPortalController, :create

    live_session :require_authenticated_user,
      on_mount: [{FanoutpagesWeb.UserAuth, :ensure_authenticated}] do
      live "/workspaces", WorkspaceLive.Index, :index
      live "/workspaces/new", WorkspaceLive.New, :new
      live "/billing", BillingLive.Index, :index

      # Settings Routes
      live "/settings/account", UserSettingsLive, :edit
      live "/settings/profile", UserSettingsLive, :edit
      live "/settings/organization", OrganizationSettingsLive, :edit
      live "/settings/team", TeamLive.Index, :index
      live "/settings/billing", BillingLive.Index, :index
      live "/settings/automation", AutomationSettingsLive, :index
    end
  end

  scope "/w/:workspace_slug", FanoutpagesWeb do
    pipe_through [:browser, :require_authenticated_user, :fetch_workspace_from_path]

    live_session :workspace_pages,
      on_mount: [
        {FanoutpagesWeb.UserAuth, :ensure_authenticated},
        {FanoutpagesWeb.UserAuth, :load_current_workspace}
      ] do
      live "/dashboard", DashboardLive, :index
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:fanoutpages, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FanoutpagesWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
