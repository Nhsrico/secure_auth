defmodule SecureAuthWeb.OAuth2Controller do
  use SecureAuthWeb, :controller

  alias SecureAuth.Accounts
  alias SecureAuthWeb.UserAuth

  def request(conn, %{"provider" => provider}) do
    # For now, redirect to a placeholder message since OAuth2 providers need proper setup
    conn
    |> put_flash(
      :info,
      "OAuth2 with #{String.capitalize(provider)} is not yet configured. Please use email/password login."
    )
    |> redirect(to: ~p"/users/log-in")
  end

  def callback(conn, %{"provider" => provider}) do
    # Placeholder for OAuth2 callback - would be implemented with proper OAuth2 setup
    conn
    |> put_flash(
      :info,
      "OAuth2 callback for #{String.capitalize(provider)} received. Please configure OAuth2 providers."
    )
    |> redirect(to: ~p"/users/log-in")
  end

  # Future implementation would include:
  # - Proper Ueberauth configuration
  # - OAuth2 provider app setup (Google, GitHub, Microsoft)
  # - Account linking logic
  # - Token management
  # - Error handling

  # Example of what the full implementation would look like:
  #
  # def callback(conn, %{"provider" => provider}) do
  #   %{assigns: %{ueberauth_auth: auth}} = conn
  #
  #   case auth do
  #     %Ueberauth.Auth{} = auth ->
  #       handle_oauth_success(conn, provider, auth)
  #
  #     %Ueberauth.Failure{} = failure ->
  #       handle_oauth_failure(conn, provider, failure)
  #
  #     _ ->
  #       conn
  #       |> put_flash(:error, "Authentication failed. Please try again.")
  #       |> redirect(to: ~p"/users/log-in")
  #   end
  # end
  #
  # defp handle_oauth_success(conn, provider, auth) do
  #   oauth_data = %{
  #     provider: provider,
  #     provider_id: auth.uid,
  #     email: auth.info.email,
  #     name: auth.info.name || "#{auth.info.first_name} #{auth.info.last_name}",
  #     avatar_url: auth.info.image,
  #     verified: auth.info.email_verified || false
  #   }
  #
  #   case find_or_create_user(oauth_data) do
  #     {:ok, user} ->
  #       conn
  #       |> put_flash(:info, "Successfully signed in with #{String.capitalize(provider)}!")
  #       |> UserAuth.log_in_user(user)
  #
  #     {:error, :email_taken} ->
  #       conn
  #       |> put_flash(:error, "Account with this email exists. Please log in normally.")
  #       |> redirect(to: ~p"/users/log-in")
  #
  #     {:error, _changeset} ->
  #       conn
  #       |> put_flash(:error, "Failed to create account. Please try again.")
  #       |> redirect(to: ~p"/users/log-in")
  #   end
  # end
end
