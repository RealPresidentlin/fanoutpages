defmodule Fanoutpages.Polar.Portal do
  @moduledoc "Handles opening Polar customer portal sessions."

  alias Fanoutpages.Polar.Client

  def customer_portal_url(customer_id) when is_binary(customer_id) do
    case Client.create_customer_session(customer_id) do
      {:ok, %{"customer_portal_url" => url}} -> {:ok, url}
      {:ok, %{"url" => url}} -> {:ok, url}
      {:error, reason} -> {:error, reason}
    end
  end

  def customer_portal_url(_), do: {:error, :missing_customer_id}
end
