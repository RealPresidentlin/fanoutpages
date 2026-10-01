defmodule Fanoutpages.Polar.Client do
  @moduledoc "Minimal client for the Polar organization API."

  @sandbox_base "https://sandbox-api.polar.sh/v1"
  @production_base "https://api.polar.sh/v1"

  def create_checkout(attrs), do: request(:post, "/checkouts", json: attrs)

  def create_customer_session(customer_id),
    do: request(:post, "/customer-sessions", json: %{customer_id: customer_id})

  def get_subscription(subscription_id), do: request(:get, "/subscriptions/#{subscription_id}")

  defp request(method, path, options \\ []) do
    options =
      Keyword.merge(
        [
          method: method,
          url: base_url() <> path,
          auth: {:bearer, Application.fetch_env!(:fanoutpages, :polar_organization_access_token)},
          headers: [{"accept", "application/json"}],
          receive_timeout: 30_000,
          decode_json: [keys: :strings]
        ],
        options
      )

    case Req.request(options) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:polar_api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp base_url do
    if Application.get_env(:fanoutpages, :polar_sandbox?, false),
      do: @sandbox_base,
      else: @production_base
  end
end
