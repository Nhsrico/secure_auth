defmodule SecureAuthWeb.OAuth2Controller do
  use SecureAuthWeb, :controller

  alias SecureAuth.Accounts
  alias SecureAuthWeb.UserAuth

  def request(conn, %{"provider" => provider}) do
    redirect(conn, to: "/auth/#{provider}")
  end

  def callback(conn, %{"provider" => provider} = params) do
    %{assigns: %{ueberauth_auth: auth}} = conn

    case auth do
      %Ueberauth.Auth{} = auth ->
        handle_oauth_success(conn, provider, auth)

      %Ueberauth.Failure{} = failure ->
        handle_oauth_failure(conn, provider, failure)

      _ ->
        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  defp handle_oauth_success(conn, provider, auth) do
    oauth_data = extract_oauth_data(provider, auth)

    case find_or_create_user(oauth_data) do
      {:ok, user} ->
        # Update OAuth login tracking
        update_oauth_login(user, oauth_data)

        conn
        |> put_flash(:info, "Successfully signed in with #{String.capitalize(provider)}!")
        |> UserAuth.log_in_user(user)

      {:error, :email_taken} ->
        conn
        |> put_flash(
          :error,
          "An account with this email already exists. Please log in normally and link your #{String.capitalize(provider)} account from settings."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to create account. Please try again.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  defp handle_oauth_failure(conn, provider, failure) do
    error_message =
      case failure.errors do
        [%{message: message} | _] -> message
        _ -> "Authentication failed"
      end

    conn
    |> put_flash(:error, "#{String.capitalize(provider)} authentication failed: #{error_message}")
    |> redirect(to: ~p"/users/log-in")
  end

  defp extract_oauth_data(provider, %Ueberauth.Auth{} = auth) do
    %{
      provider: provider,
      provider_id: auth.uid,
      email: auth.info.email,
      name: auth.info.name || "#{auth.info.first_name} #{auth.info.last_name}",
      avatar_url: auth.info.image,
      verified: auth.info.email_verified || false,
      access_token: get_in(auth.credentials, [:token]),
      refresh_token: get_in(auth.credentials, [:refresh_token]),
      expires_at: get_in(auth.credentials, [:expires_at])
    }
  end

  defp find_or_create_user(oauth_data) do
    # Try to find existing user by provider ID
    case find_user_by_provider(oauth_data.provider, oauth_data.provider_id) do
      %Accounts.User{} = user ->
        {:ok, user}

      nil ->
        # Try to find by email
        case Accounts.get_user_by_email(oauth_data.email) do
          %Accounts.User{} = user ->
            # Link OAuth account to existing user
            link_oauth_account(user, oauth_data)

          nil ->
            # Create new user
            create_oauth_user(oauth_data)
        end
    end
  end

  defp find_user_by_provider("google", provider_id) do
    Accounts.get_user_by(google_id: provider_id)
  end

  defp find_user_by_provider("github", provider_id) do
    Accounts.get_user_by(github_id: provider_id)
  end

  defp find_user_by_provider("microsoft", provider_id) do
    Accounts.get_user_by(microsoft_id: provider_id)
  end

  defp find_user_by_provider(_, _), do: nil

  defp link_oauth_account(user, oauth_data) do
    attrs = build_oauth_attrs(oauth_data)
    Accounts.update_user_oauth(user, attrs)
  end

  defp create_oauth_user(oauth_data) do
    # Generate a placeholder for required fields
    attrs = %{
      email: oauth_data.email,
      name: oauth_data.name,
      # Placeholder - user can update later
      phone_number: "+1000000000",
      # Placeholder - user can update later
      next_of_kin_passport: "OAUTH_PLACEHOLDER",
      oauth_email_verified: oauth_data.verified,
      oauth_avatar_url: oauth_data.avatar_url,
      oauth_first_login: DateTime.utc_now(),
      confirmed_at: if(oauth_data.verified, do: DateTime.utc_now(), else: nil)
    }

    # Add provider-specific ID
    attrs = Map.put(attrs, :"#{oauth_data.provider}_id", oauth_data.provider_id)

    # Add encrypted tokens
    if oauth_data.access_token do
      tokens = %{
        access_token: oauth_data.access_token,
        refresh_token: oauth_data.refresh_token,
        expires_at: oauth_data.expires_at
      }

      encrypted_tokens = Base.encode64(:erlang.term_to_binary(tokens))
      attrs = Map.put(attrs, :oauth_tokens_encrypted, encrypted_tokens)
    end

    Accounts.register_oauth_user(attrs)
  end

  defp build_oauth_attrs(oauth_data) do
    attrs = %{
      oauth_email_verified: oauth_data.verified,
      oauth_avatar_url: oauth_data.avatar_url,
      oauth_last_login: DateTime.utc_now()
    }

    # Add provider-specific ID
    attrs = Map.put(attrs, :"#{oauth_data.provider}_id", oauth_data.provider_id)

    # Add encrypted tokens
    if oauth_data.access_token do
      tokens = %{
        access_token: oauth_data.access_token,
        refresh_token: oauth_data.refresh_token,
        expires_at: oauth_data.expires_at
      }

      encrypted_tokens = Base.encode64(:erlang.term_to_binary(tokens))
      attrs = Map.put(attrs, :oauth_tokens_encrypted, encrypted_tokens)
    end

    attrs
  end

  defp update_oauth_login(user, oauth_data) do
    attrs = %{oauth_last_login: DateTime.utc_now()}
    Accounts.update_user_oauth(user, attrs)
  end
end
