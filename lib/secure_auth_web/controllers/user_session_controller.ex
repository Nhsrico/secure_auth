defmodule SecureAuthWeb.UserSessionController do
  use SecureAuthWeb, :controller

  alias SecureAuthWeb.Plugs.RateLimitPlug
  alias SecureAuth.RateLimiter

  alias SecureAuth.Accounts
  alias SecureAuthWeb.UserAuth

  plug RateLimitPlug,
       [
         action: :login,
         message: "Too many login attempts. Please try again in 15 minutes.",
         redirect_to: "/users/log-in"
       ]
       when action in [:create]

  def new_registration(conn, _params) do
    if conn.assigns.current_scope do
      redirect(conn, to: SecureAuthWeb.UserAuth.signed_in_path(conn))
    else
      changeset = Accounts.change_user_registration(%Accounts.User{})
      render(conn, :new_registration, changeset: changeset)
    end
  end

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    create(conn, params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(conn, ~p"/users/log-in/#{&1}")
          )

        conn
        |> put_flash(
          :info,
          "Account created successfully! An email was sent to #{user.email} to confirm your account."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_flash(:error, "There was an error creating your account. Please check the form and try again.")
        |> redirect(to: ~p"/users/register")
    end
  end

  defp create(conn, %{"user" => user_params}, _info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # Reset rate limit on successful login
      reset_login_rate_limit(conn)

      # Check if user has 2FA enabled
      if user.two_factor_enabled do
        # Store user in session temporarily and redirect to 2FA verification
        conn
        |> put_session(:pending_user_id, user.id)
        |> put_session(:remember_me, Map.get(user_params, "remember_me", "false"))
        |> put_flash(:info, "Please complete two-factor authentication")
        |> redirect(to: ~p"/users/verify-2fa")
      else
        # Normal login flow without 2FA
        UserAuth.log_in_user(conn, user, user_params)
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def verify_2fa(conn, %{"user" => %{"totp_code" => code}}) do
    user_id = get_session(conn, :pending_user_id)
    remember_me = get_session(conn, :remember_me)

    case {user_id, user_id && Accounts.get_user!(user_id)} do
      {user_id, user} when not is_nil(user_id) and not is_nil(user) ->
        if Accounts.verify_totp(user, code) do
          # Reset 2FA rate limit on successful verification
          reset_2fa_rate_limit(conn)

          conn
          |> delete_session(:pending_user_id)
          |> delete_session(:remember_me)
          |> UserAuth.log_in_user(user, %{"remember_me" => remember_me})
        else
          conn
          |> put_flash(:error, "Invalid authentication code. Please try again.")
          |> redirect(to: ~p"/users/verify-2fa")
        end

      _ ->
        conn
        |> put_flash(:error, "Session expired. Please log in again.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def verify_2fa(conn, %{"user" => %{"backup_code" => code}}) do
    user_id = get_session(conn, :pending_user_id)
    remember_me = get_session(conn, :remember_me)

    case {user_id, user_id && Accounts.get_user!(user_id)} do
      {user_id, user} when not is_nil(user_id) and not is_nil(user) ->
        if Accounts.verify_backup_code(user, code) do
          # Reset 2FA rate limit on successful verification
          reset_2fa_rate_limit(conn)

          conn
          |> delete_session(:pending_user_id)
          |> delete_session(:remember_me)
          |> UserAuth.log_in_user(user, %{"remember_me" => remember_me})
        else
          conn
          |> put_flash(:error, "Invalid backup code. Please try again.")
          |> redirect(to: ~p"/users/verify-2fa")
        end

      _ ->
        conn
        |> put_flash(:error, "Session expired. Please log in again.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  def update_password(conn, %{"user_id" => user_id, "user_token" => _user_token} = params) do
    if user = Accounts.get_user!(user_id) do
      case Accounts.update_user_password(user, params["user"]) do
        {:ok, user, _expired_tokens} ->
          # Reset rate limit on successful password update
          reset_login_rate_limit(conn)

          conn
          |> put_session(:user_return_to, ~p"/users/settings")
          |> UserAuth.log_in_user(user, %{})

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Invalid password or token")
          |> redirect(to: ~p"/users/log-in")
      end
    else
      conn
      |> put_flash(:error, "Invalid user")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  # Private helper functions for rate limit reset

  defp reset_login_rate_limit(conn) do
    identifier = get_client_identifier(conn)
    RateLimiter.reset_rate_limit(identifier, :login)
  end

  defp reset_2fa_rate_limit(conn) do
    identifier = get_client_identifier(conn)
    RateLimiter.reset_rate_limit(identifier, :two_fa)
  end

  defp get_client_identifier(conn) do
    # Use IP address as the identifier (same as in RateLimitPlug)
    case conn.remote_ip do
      {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> "unknown"
    end
  end
end
