defmodule FanoutpagesWeb.UserRegistrationLive do
  use FanoutpagesWeb, :live_view

  alias Fanoutpages.Accounts
  alias Fanoutpages.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div id="registration-page" class="mx-auto w-full space-y-8">
        <section class="space-y-2">
          <nav
            aria-label="Breadcrumb"
            class="flex items-center gap-2 text-xs font-medium text-base-content/50"
          >
            <.link navigate={~p"/"} class="hover:text-base-content transition-colors">
              Fanout Pages
            </.link>
            <span>/</span>
            <span class="text-base-content font-semibold">Get Started</span>
          </nav>
          <h1 class="text-3xl font-black tracking-tight text-base-content sm:text-4xl">
            Start autonomous social orchestration
          </h1>
          <p class="text-sm text-base-content/60 max-w-2xl leading-relaxed">
            Create your account to dispatch autonomous multi-agent content pipelines across X, LinkedIn, Threads, and Instagram.
          </p>
        </section>

        <section class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_20rem]">
          <!-- Left Main Form Card -->
          <div class="card bg-base-100 border border-base-200 shadow-sm">
            <div class="card-body p-6 sm:p-8 space-y-6">
              <.form
                for={@form}
                id="registration_form"
                phx-submit="save"
                phx-change="validate"
                phx-trigger-action={@trigger_submit}
                action={~p"/users/log_in?_action=registered"}
                method="post"
                class="space-y-6"
              >
                <!-- Operational Mode Selector -->
                <div class="space-y-3">
                  <label class="block text-[11px] font-medium uppercase tracking-wider text-base-content/50">
                    How will you use Fanout Pages?
                  </label>

                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <button
                      type="button"
                      phx-click="select_account_type"
                      phx-value-type="business"
                      class={[
                        "p-4 rounded-xl border text-left transition-all relative flex flex-col justify-between cursor-pointer",
                        if(@account_type == "business",
                          do: "border-primary bg-primary/5 ring-1 ring-primary",
                          else: "border-base-200 hover:border-base-300 bg-base-100"
                        )
                      ]}
                    >
                      <div>
                        <div class="flex items-center justify-between">
                          <div class="font-bold text-sm text-base-content flex items-center gap-2">
                            <.icon name="hero-briefcase" class="size-4 text-primary" /> My Business
                          </div>
                          <span
                            :if={@account_type == "business"}
                            class="size-2 rounded-full bg-primary"
                          ></span>
                        </div>
                        <p class="text-xs text-base-content/60 mt-1 leading-relaxed">
                          Autonomous publishing for our dedicated company brand.
                        </p>
                      </div>
                      <div class="mt-3 text-[11px] font-semibold text-primary">
                        Single brand workspace
                      </div>
                    </button>

                    <button
                      type="button"
                      phx-click="select_account_type"
                      phx-value-type="agency"
                      class={[
                        "p-4 rounded-xl border text-left transition-all relative flex flex-col justify-between cursor-pointer",
                        if(@account_type == "agency",
                          do: "border-primary bg-primary/5 ring-1 ring-primary",
                          else: "border-base-200 hover:border-base-300 bg-base-100"
                        )
                      ]}
                    >
                      <div>
                        <div class="flex items-center justify-between">
                          <div class="font-bold text-sm text-base-content flex items-center gap-2">
                            <.icon name="hero-building-office-2" class="size-4 text-primary" /> Agency
                          </div>
                          <span :if={@account_type == "agency"} class="size-2 rounded-full bg-primary"></span>
                        </div>
                        <p class="text-xs text-base-content/60 mt-1 leading-relaxed">
                          Managing multi-brand client workspaces and agent fleets.
                        </p>
                      </div>
                      <div class="mt-3 text-[11px] font-semibold text-primary">
                        Multi-brand client workspaces
                      </div>
                    </button>
                  </div>

                  <input type="hidden" name="user[account_type]" value={@account_type} />
                </div>

                <div class="border-t border-base-200 pt-6 space-y-4">
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label class="text-[11px] font-medium text-base-content/50 uppercase tracking-wider block mb-1">
                        Your Full Name
                      </label>
                      <.input
                        field={@form[:name]}
                        type="text"
                        placeholder="e.g. Alex Morgan"
                        required
                        class="input input-sm input-bordered w-full rounded-lg text-xs"
                      />
                    </div>

                    <div>
                      <label class="text-[11px] font-medium text-base-content/50 uppercase tracking-wider block mb-1">
                        {if(@account_type == "agency", do: "Agency Name", else: "Company Name")}
                      </label>
                      <.input
                        field={@form[:organization_name]}
                        type="text"
                        placeholder={
                          if(@account_type == "agency",
                            do: "e.g. Apex Media Agency",
                            else: "e.g. Acme Health Corp"
                          )
                        }
                        required
                        class="input input-sm input-bordered w-full rounded-lg text-xs"
                      />
                    </div>
                  </div>

                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label class="text-[11px] font-medium text-base-content/50 uppercase tracking-wider block mb-1">
                        Work Email Address
                      </label>
                      <.input
                        field={@form[:email]}
                        type="email"
                        placeholder="you@company.com"
                        required
                        class="input input-sm input-bordered w-full rounded-lg text-xs"
                      />
                    </div>

                    <div>
                      <label class="text-[11px] font-medium text-base-content/50 uppercase tracking-wider block mb-1">
                        Password (min 8 characters)
                      </label>
                      <.input
                        field={@form[:password]}
                        type="password"
                        placeholder="••••••••"
                        required
                        class="input input-sm input-bordered w-full rounded-lg text-xs"
                      />
                    </div>
                  </div>
                </div>

                <div class="pt-2">
                  <button
                    type="submit"
                    phx-disable-with="Creating workspace..."
                    class="btn btn-sm btn-primary rounded-lg text-xs font-medium px-6 shadow-none"
                  >
                    Create Account & Start Workspace
                  </button>
                </div>
              </.form>
            </div>
          </div>

          <!-- Right Sidebar Card (TenderFolder Style) -->
          <div class="space-y-4">
            <div class="card bg-base-100 border border-base-200 shadow-sm">
              <div class="card-body p-6 space-y-4">
                <div>
                  <h2 class="text-sm font-bold text-base-content">Already registered?</h2>
                  <p class="mt-1 text-xs leading-relaxed text-base-content/60">
                    Use your existing credentials to access your autonomous dispatch dashboard.
                  </p>
                  <.link
                    navigate={~p"/users/log_in"}
                    class="btn btn-outline btn-sm rounded-lg text-xs mt-3 w-full font-medium"
                  >
                    Log in
                  </.link>
                </div>

                <div class="border-t border-base-200 pt-4 space-y-2">
                  <h3 class="text-xs font-semibold text-base-content">Included in trial:</h3>
                  <ul class="space-y-1.5 text-xs text-base-content/60">
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check" class="size-3.5 text-primary shrink-0" />
                      <span>Zero credit card required upfront</span>
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check" class="size-3.5 text-primary shrink-0" />
                      <span>Full autonomous agent runtime & MCP</span>
                    </li>
                    <li class="flex items-center gap-2">
                      <.icon name="hero-check" class="size-3.5 text-primary shrink-0" />
                      <span>Multi-channel cross-posting engine</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <div class="rounded-xl border border-dashed border-base-300 p-4 text-xs text-base-content/50 leading-relaxed">
              <p>
                <strong class="text-base-content/70">Tip:</strong>
                Use your work email domain so team members can effortlessly recognize invitations and share credentials securely.
              </p>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(trigger_submit: false)
     |> assign(account_type: "agency")
     |> assign_form(changeset)}
  end

  def handle_event("select_account_type", %{"type" => type}, socket)
      when type in ["business", "agency"] do
    {:noreply, assign(socket, :account_type, type)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "account_type", socket.assigns.account_type)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_registration(user)

        {:noreply,
         socket
         |> assign(trigger_submit: true)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "user"))
  end
end
