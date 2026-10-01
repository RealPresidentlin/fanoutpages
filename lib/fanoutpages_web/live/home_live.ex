defmodule FanoutpagesWeb.HomeLive do
  use FanoutpagesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Fanout Pages — Social Media Scheduler for People & Agents")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} full_width>
      <div
        id="landing-page"
        class="min-h-screen overflow-hidden bg-base-100 text-base-content selection:bg-primary selection:text-primary-content"
      >
        <!-- Hero Section -->
        <section class="border-b border-base-300/70">
          <div class="mx-auto grid max-w-7xl gap-12 px-6 py-16 lg:grid-cols-[1.1fr_0.9fr] lg:items-center lg:py-24">
            <div>
              <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-primary/20 bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-6">
                <.icon name="hero-sparkles" class="size-4" /> Next-Gen Social Operations
              </div>

              <h1 class="max-w-4xl text-5xl font-black tracking-[-0.045em] sm:text-6xl lg:text-7xl">
                Social scheduling for people and <span class="text-primary">autonomous agents.</span>
              </h1>

              <p class="mt-7 max-w-2xl text-lg leading-8 text-base-content/65">
                FanoutPages gives your team and their AI agents one unified workspace to coordinate,
                draft, approve, and publish to Twitter/X, LinkedIn, Threads, and Instagram.
              </p>

              <div class="mt-9 flex flex-wrap gap-3">
                <.link
                  navigate={primary_path(@current_scope)}
                  class="btn btn-primary btn-lg rounded-xl shadow-xl shadow-primary/20 transition hover:-translate-y-0.5"
                >
                  {primary_label(@current_scope)} <.icon name="hero-arrow-right" class="size-5" />
                </.link>
                <a href="#features" class="btn btn-outline btn-lg rounded-xl">See how it works</a>
              </div>

              <p class="mt-5 flex items-center gap-2 text-sm font-semibold text-base-content/55">
                <.icon name="hero-check-circle" class="size-5 text-success" />
                Free 14-day trial · No credit card required · Full API & MCP access
              </p>
            </div>

            <!-- Hero Right Card Mockup -->
            <div class="relative mx-auto w-full max-w-xl">
              <div class="absolute -inset-5 -z-10 rotate-2 rounded-[2.5rem] bg-primary/10"></div>
              <div class="card card-lg bg-base-100 border border-base-300 shadow-2xl">
                <div class="card-body">
                  <div class="flex items-center justify-between gap-4 border-b border-base-200 pb-4">
                    <div>
                      <p class="text-lg font-black">Unified Agent & Human Queue</p>
                      <p class="text-xs text-base-content/50">Cross-platform dispatch engine</p>
                    </div>
                    <span class="flex size-11 shrink-0 items-center justify-center rounded-2xl bg-primary text-primary-content">
                      <.icon name="hero-megaphone" class="size-6" />
                    </span>
                  </div>

                  <div class="mt-4 space-y-3">
                    <div class="flex items-start gap-3 rounded-xl border border-base-200 bg-base-200/50 p-3.5">
                      <div class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                        <.icon name="hero-cpu-chip" class="size-5" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="flex items-center justify-between">
                          <p class="text-xs font-bold text-base-content">Research & Curate Agent</p>
                          <span class="badge badge-success badge-xs font-semibold">Ready for Review</span>
                        </div>
                        <p class="text-xs text-base-content/65 mt-0.5 truncate">
                          Drafted 3-post breakdown of today's LLM benchmark releases
                        </p>
                      </div>
                    </div>

                    <div class="flex items-start gap-3 rounded-xl border border-base-200 bg-base-200/50 p-3.5">
                      <div class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-secondary/10 text-secondary">
                        <.icon name="hero-user" class="size-5" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="flex items-center justify-between">
                          <p class="text-xs font-bold text-base-content">Lincoln Vance (Human)</p>
                          <span class="badge badge-primary badge-xs font-semibold">Scheduled</span>
                        </div>
                        <p class="text-xs text-base-content/65 mt-0.5 truncate">
                          Publishing to LinkedIn, Twitter/X & Threads tomorrow at 9:00 AM
                        </p>
                      </div>
                    </div>

                    <div class="flex items-start gap-3 rounded-xl border border-base-200 bg-base-200/50 p-3.5">
                      <div class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent">
                        <.icon name="hero-bolt" class="size-5" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="flex items-center justify-between">
                          <p class="text-xs font-bold text-base-content">MCP Dispatch Engine</p>
                          <span class="badge badge-ghost badge-xs font-mono">200 OK</span>
                        </div>
                        <p class="text-xs text-base-content/65 mt-0.5 truncate">
                          Webhook event delivered to external agent runtime
                        </p>
                      </div>
                    </div>
                  </div>

                  <div class="mt-4 grid grid-cols-3 gap-2 border-t border-base-200 pt-3 text-center">
                    <div class="rounded-xl bg-base-200/60 p-2.5">
                      <div class="text-base font-black">25+</div>
                      <div class="text-[10px] uppercase font-bold text-base-content/45 tracking-wider">
                        Accounts
                      </div>
                    </div>
                    <div class="rounded-xl bg-base-200/60 p-2.5">
                      <div class="text-base font-black">15</div>
                      <div class="text-[10px] uppercase font-bold text-base-content/45 tracking-wider">
                        Agents
                      </div>
                    </div>
                    <div class="rounded-xl bg-base-200/60 p-2.5">
                      <div class="text-base font-black text-success">100%</div>
                      <div class="text-[10px] uppercase font-bold text-base-content/45 tracking-wider">
                        Delivered
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- Feature Pillars Section -->
        <section id="features" class="scroll-mt-6 border-b border-base-300/70 py-20">
          <div class="mx-auto max-w-7xl px-6">
            <header class="max-w-3xl">
              <h2 class="text-4xl font-black tracking-tight sm:text-5xl">
                Designed for modern social operations.
              </h2>
              <p class="mt-4 text-base leading-7 text-base-content/60">
                Whether you are an agency managing 30 clients or a team scaling in-house social, FanoutPages gives you total control.
              </p>
            </header>

            <div class="mt-12 grid gap-6 md:grid-cols-3">
              <div class="card rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm transition hover:shadow-md">
                <div class="flex size-12 items-center justify-center rounded-xl bg-primary/10 text-primary font-bold mb-6">
                  <.icon name="hero-building-office-2" class="size-6" />
                </div>
                <h3 class="text-xl font-bold mb-2">Isolated Workspaces</h3>
                <p class="text-sm leading-relaxed text-base-content/65">
                  Clean data isolation for every client or brand. Manage multiple client posting calendars, distinct tokens, and team members under one organization account.
                </p>
              </div>

              <div class="card rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm transition hover:shadow-md">
                <div class="flex size-12 items-center justify-center rounded-xl bg-secondary/10 text-secondary font-bold mb-6">
                  <.icon name="hero-cpu-chip" class="size-6" />
                </div>
                <h3 class="text-xl font-bold mb-2">Autonomous Agent Fleet</h3>
                <p class="text-sm leading-relaxed text-base-content/65">
                  Deploy AI workers directly into your schedule queue. Humans retain full review and approval before any content is published to social networks.
                </p>
              </div>

              <div class="card rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm transition hover:shadow-md">
                <div class="flex size-12 items-center justify-center rounded-xl bg-accent/10 text-accent font-bold mb-6">
                  <.icon name="hero-code-bracket" class="size-6" />
                </div>
                <h3 class="text-xl font-bold mb-2">First-Class API & MCP</h3>
                <p class="text-sm leading-relaxed text-base-content/65">
                  Connect external agents, Cursor, Claude Code, or custom pipelines through Model Context Protocol (MCP) and REST APIs on every plan tier.
                </p>
              </div>
            </div>
          </div>
        </section>

        <!-- CTA Banner -->
        <section class="mx-auto max-w-7xl px-6 py-20">
          <div class="rounded-3xl border border-base-300 bg-base-100 p-10 sm:p-16 text-center shadow-xl">
            <div class="mx-auto max-w-2xl space-y-4">
              <h2 class="text-3xl font-black tracking-tight sm:text-5xl">
                Ready to orchestrate your social channels?
              </h2>
              <p class="text-base leading-relaxed text-base-content/65">
                Join forward-looking agencies and creators combining human oversight with autonomous agents.
              </p>
            </div>

            <div class="mt-8 flex justify-center gap-3">
              <.link
                navigate={primary_path(@current_scope)}
                class="btn btn-primary btn-lg rounded-xl font-bold shadow-xl shadow-primary/20"
              >
                {primary_label(@current_scope)}
                <.icon name="hero-arrow-right" class="size-5" />
              </.link>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp primary_path(%{user: %{}}), do: ~p"/dashboard"
  defp primary_path(_), do: ~p"/users/register"

  defp primary_label(%{user: %{}}), do: "Open dashboard"
  defp primary_label(_), do: "Start free"
end
