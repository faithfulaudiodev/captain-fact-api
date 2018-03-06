defmodule CaptainFact.Authenticator do
  @moduledoc """
  Handle all authentication intelligence
  """

  alias DB.Repo
  alias DB.Schema.User
  alias CaptainFact.Authenticator.ProviderInfos
  alias CaptainFact.Authenticator.OAuth

  @doc """
  Get user from its email address and check password.
  Returns nil if no User for email or if password is invalid.
  """
  def get_user_for_email_password(email, password) do
    with user when not is_nil(user) <- Repo.get_by(User, email: email),
         true <- validate_pass(user.encrypted_password, password) do
      user
    else
      _ -> nil
    end
  end

  @doc"""
  Get a user from third party info, creating it if necessary
  """
  def get_user_by_third_party!(provider, code, invitation_token \\ nil) do
    case OAuth.fetch_user_from_third_party(provider, code) do
      provider_infos = %ProviderInfos{} ->
        OAuth.find_or_create_user!(provider_infos, invitation_token)
      error ->
        error
    end
  end

  @doc"""
  Associate a third party account with an existing CaptainFact account
  """
  def associate_user_with_third_party(user, provider, code) do
    case OAuth.fetch_user_from_third_party(provider, code) do
      provider_infos = %ProviderInfos{} ->
        OAuth.link_provider!(user, provider_infos)
      error ->
        error
    end
  end

  @doc"""
  Dissociate given third party from user's account
  """
  def disscociate_third_party(user, provider) do
    OAuth.unlink_provider(user, provider)
  end

  defp validate_pass(_encrypted, password) when password in [nil, ""], do: false
  defp validate_pass(encrypted, password), do: Comeonin.Bcrypt.checkpw(password, encrypted)
end