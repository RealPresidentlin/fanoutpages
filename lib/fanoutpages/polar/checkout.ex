defmodule Fanoutpages.Polar.Checkout do
  @moduledoc "Handles checkout creation for Polar subscriptions."

  alias Fanoutpages.Polar.Client
  alias Fanoutpages.Billing.PlanConfig

  def create_checkout_session(organization, plan, interval, success_url) do
    product_id = PlanConfig.product_id(plan, interval)

    if is_nil(product_id) do
      {:error, :invalid_product}
    else
      customer_email =
        case organization do
          %{created_by_user: %Fanoutpages.Accounts.User{email: email}} ->
            email

          %{created_by_user_id: user_id} when is_binary(user_id) ->
            case Fanoutpages.Repo.get(Fanoutpages.Accounts.User, user_id) do
              %Fanoutpages.Accounts.User{email: email} -> email
              _ -> nil
            end

          _ ->
            nil
        end

      attrs = %{
        product_id: product_id,
        success_url: success_url,
        customer_email: customer_email,
        metadata: %{
          organization_id: organization.id,
          plan: plan,
          interval: to_string(interval)
        }
      }

      attrs =
        if organization.polar_customer_id do
          Map.put(attrs, :customer_id, organization.polar_customer_id)
        else
          attrs
        end

      case Client.create_checkout(attrs) do
        {:ok, %{"url" => url}} -> {:ok, url}
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
