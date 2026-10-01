defmodule FanoutpagesWeb.HomeLive do
  use FanoutpagesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Social media scheduling for people and their AI agents."
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} shell={:plain} full_width>
      <div
        id="landing-page"
        class="min-h-screen overflow-hidden bg-base-100 text-base-content selection:bg-primary selection:text-primary-content"
      >
        <!-- Hero Section -->
        <section>
          <div class="mx-auto max-w-7xl px-6 py-16 lg:py-24">
            <h1 class="max-w-4xl text-5xl font-black tracking-[-0.045em] sm:text-6xl lg:text-7xl">
              Social media scheduling for people and
              <span class="text-primary">their AI agents.</span>
            </h1>

            <p class="mt-7 max-w-2xl text-lg leading-8 text-base-content/65">
              FanoutPages gives your human and AI agents one shared workspace.
              Draft, adapt, review, schedule, and publish to LinkedIn member profiles and Threads.
            </p>

            <div class="mt-9 flex flex-wrap gap-3">
              <.link
                navigate={primary_path(@current_scope)}
                class="btn btn-primary btn-lg rounded-xl transition hover:-translate-y-0.5"
              >
                {primary_label(@current_scope)} <.icon name="hero-arrow-right" class="size-5" />
              </.link>
              <a href="#features" class="btn btn-ghost btn-lg">See how it works</a>
            </div>

            <p class="mt-5 flex items-center gap-2 text-sm font-semibold text-base-content/55">
              <.icon name="hero-check-circle" class="size-5 text-success" />
              Free 14-day trial · No credit card required · Scoped REST and MCP access
            </p>
          </div>
        </section>

        <!-- Feature Pillars Section -->
        <section id="features" class="scroll-mt-6 py-20">
          <div class="mx-auto max-w-7xl px-6">
            <header class="max-w-3xl">
              <h2 class="text-4xl font-black tracking-tight sm:text-5xl">
                Built for modern social media management.
              </h2>
              <p class="mt-4 text-base leading-7 text-base-content/60">
                Manage your brand or client workspaces with clear permissions and publishing history.
              </p>
            </header>

            <div class="mt-12 grid gap-x-6 gap-y-12 md:grid-cols-3">
              <div>
                <.icon name="hero-building-office-2" class="size-7 text-primary mb-4" />
                <h3 class="text-xl font-bold mb-2">Separate Workspaces</h3>
                <p class="text-sm leading-relaxed text-base-content/65">
                  Keep data separate for each client or brand. Manage separate publishing schedules and team access under one organization.
                </p>
              </div>

              <div>
                <.icon name="hero-cpu-chip" class="size-7 text-secondary mb-4" />
                <h3 class="text-xl font-bold mb-2">Bring Your Own AI Agents</h3>
                <p class="text-sm leading-relaxed text-base-content/65">
                  Connect externally hosted AI agents through MCP. They draft and submit content for review; your team schedules and publishes it. Require approval before publishing when your organization enables that policy.
                </p>
              </div>

              <div>
                <.icon name="hero-code-bracket" class="size-7 text-accent mb-4" />
                <h3 class="text-xl font-bold mb-2">MCP Access</h3>
                <p class="text-sm leading-relaxed text-base-content/65">
                  MCP to read workspace data, create drafts, submit them for review, and inspect publication status. MCP also supports draft updates.
                </p>
              </div>
            </div>
          </div>
        </section>

        <!-- CTA Section -->
        <section class="mx-auto max-w-7xl px-6 pb-20 pt-4 text-center">
          <div class="mx-auto max-w-2xl space-y-4">
            <h2 class="text-3xl font-black tracking-tight sm:text-5xl">
              Ready to manage your social media channels?
            </h2>
            <p class="text-base leading-relaxed text-base-content/65">
              Join teams that combine human decision-making with the AI agents they already use.
            </p>
          </div>

          <div class="mt-8 flex justify-center gap-3">
            <.link
              navigate={primary_path(@current_scope)}
              class="btn btn-primary btn-lg rounded-xl font-bold"
            >
              {primary_label(@current_scope)}
              <.icon name="hero-arrow-right" class="size-5" />
            </.link>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp primary_path(%{user: %{}}), do: ~p"/dashboard"
  defp primary_path(_), do: ~p"/users/register"

  defp primary_label(%{user: %{}}), do: "Open dashboard"
  defp primary_label(_), do: "Start my free trial"
end
