defmodule Fanoutpages.Organizations.OrganizationNotifier do
  @moduledoc "Delivers emails related to organization invitations."
  import Swoosh.Email

  alias Fanoutpages.Mailer

  def deliver_organization_invite(invite, url) do
    email =
      new()
      |> to(invite.email)
      |> from({"Fanout Pages", "invites@fanoutpages.com"})
      |> subject("You've been invited to #{invite.organization.name} on Fanout Pages")
      |> text_body("""
      ==============================

      Hi,

      You have been invited to join #{invite.organization.name} as #{invite.role} on Fanout Pages.

      Click the link below to accept your invitation:

      #{url}

      This invite expires in 7 days.

      ==============================
      """)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
