defmodule SecureAuth.Accounts.UserNotifier do
  import Swoosh.Email

  alias SecureAuth.Mailer
  alias SecureAuth.Accounts.User

  defp disp(term, label), do: IO.inspect(term, label: label, limit: :infinity)


  # Delivers the email using the application mailer, with debug output.
defp deliver(recipient, subject, body) do
  # Build the email
  email =
    new()
    |> to(recipient)
    |> from({"SecureAuth", "no-reply@nethomesolutions.com"})
    |> subject(subject)
    |> text_body(body)

  disp(email, "deliver/3 email payload")

  # Show effective mailer config (redact API key if present)
  mailer_cfg =
    Application.get_env(:secure_auth, SecureAuth.Mailer) || []
  redacted_cfg =
    case mailer_cfg[:api_key] do
      nil -> mailer_cfg
      key when is_binary(key) ->
        # keep only last 4 chars visible
        put_in(mailer_cfg[:api_key], "***" <> String.slice(key, max(byte_size(key) - 4, 0), 4))
      _ -> mailer_cfg
    end

  disp(redacted_cfg, "deliver/3 mailer cfg (redacted)")
  disp(Application.get_env(:swoosh, :api_client), "deliver/3 swoosh :api_client")
  disp(System.get_env("SENDGRID_API_HOST"), "deliver/3 SENDGRID_API_HOST")

  # Send and log the result
  res = SecureAuth.Mailer.deliver(email)
  disp(res, "deliver/3 Mailer.deliver result")

  case res do
    {:ok, _meta} ->
      {:ok, email}

    {:error, reason} ->
      # reason might be {:http_error, {status, body}} or {status, map} etc.
      disp(reason, "deliver/3 error reason")
      {:error, reason}
  end
end





  # # Delivers the email using the application mailer.
  # defp deliver(recipient, subject, body) do
  #   email =
  #     new()
  #     |> to(recipient)
  #     |> from({"SecureAuth", "no-reply@nethomesolutions.com"})
  #     |> subject(subject)
  #     |> text_body(body)

  #   with {:ok, _metadata} <- Mailer.deliver(email) do
  #     {:ok, email}
  #   end
  # end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
