defmodule Fanoutpages.Accounts do
  @moduledoc """
  The Accounts context for user authentication and credentials.
  """

  import Ecto.Query, warn: false
  alias Fanoutpages.Repo
  alias Fanoutpages.Accounts.{User, UserToken, UserNotifier}
  alias Fanoutpages.Organizations.{Organization, OrganizationMembership}
  alias Fanoutpages.Workspaces.{Workspace, WorkspaceMembership}

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id) when is_binary(id), do: Repo.get(User, id)
  def get_user(_), do: nil

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def register_user(attrs) do
    org_name = Map.get(attrs, "organization_name") || Map.get(attrs, :organization_name)
    user_name = Map.get(attrs, "name") || Map.get(attrs, :name)
    account_type = Map.get(attrs, "account_type") || Map.get(attrs, :account_type) || "agency"
    default_plan = if account_type == "business", do: "starter", else: "core"

    effective_org_name =
      if is_binary(org_name) and String.trim(org_name) != "",
        do: String.trim(org_name),
        else: "#{user_name}'s Workspace"

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, attrs))
    |> Ecto.Multi.insert(:organization, fn %{user: user} ->
      slug = generate_slug(effective_org_name, Organization)

      %Organization{
        name: effective_org_name,
        slug: slug,
        account_type: account_type,
        created_by_user_id: user.id,
        plan: default_plan,
        subscription_status: "trialing"
      }
    end)
    |> Ecto.Multi.insert(:org_membership, fn %{user: user, organization: org} ->
      %OrganizationMembership{
        organization_id: org.id,
        user_id: user.id,
        role: "owner"
      }
    end)
    |> Ecto.Multi.insert(:workspace, fn %{organization: org} ->
      workspace_name = "Default Brand"
      slug = Fanoutpages.Workspaces.build_slug(org, "main")

      %Workspace{
        name: workspace_name,
        slug: slug,
        organization_id: org.id
      }
    end)
    |> Ecto.Multi.insert(:workspace_membership, fn %{user: user, workspace: ws} ->
      %WorkspaceMembership{
        workspace_id: ws.id,
        user_id: user.id
      }
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
      {:error, _step, changeset, _} -> {:error, changeset}
    end
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.validate_current_password(password)
      |> User.password_changeset(attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.validate_current_password(password)
    |> User.email_changeset(attrs)
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: sent_to} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, sent_to, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.by_user_and_contexts_query(user, [{:context, context}])
    )
  end

  defp generate_slug(name, schema) do
    base =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    base = if base == "", do: "brand", else: base

    candidate = base
    suffix = :rand.uniform(9999)

    if Repo.exists?(from s in schema, where: s.slug == ^candidate) do
      "#{candidate}-#{suffix}"
    else
      candidate
    end
  end
end
