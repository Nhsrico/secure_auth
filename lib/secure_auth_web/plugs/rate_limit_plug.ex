defmodule SecureAuthWeb.Plugs.RateLimitPlug do
  @moduledoc """
  Plug for rate limiting requests based on IP address and action type.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias SecureAuth.RateLimiter

  def init(opts) do
    action = Keyword.get(opts, :action, :default)
    message = Keyword.get(opts, :message, "Too many requests. Please try again later.")
    redirect_to = Keyword.get(opts, :redirect_to, nil)

    %{
      action: action,
      message: message,
      redirect_to: redirect_to
    }
  end

  def call(conn, %{action: action, message: message, redirect_to: redirect_to}) do
    identifier = get_identifier(conn)

    case RateLimiter.check_rate_limit(identifier, action) do
      {:ok, remaining} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(get_limit(action)))
        |> put_resp_header("x-ratelimit-remaining", to_string(remaining))

      {:error, :rate_limited, retry_after_ms} ->
        retry_after_seconds = div(retry_after_ms, 1000)

        conn
        |> put_resp_header("x-ratelimit-limit", to_string(get_limit(action)))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> put_resp_header("retry-after", to_string(retry_after_seconds))
        |> handle_rate_limited(message, redirect_to)
        |> halt()
    end
  end

  defp get_identifier(conn) do
    # Use IP address as the primary identifier
    case get_client_peer_data(conn) do
      %{address: {a, b, c, d}} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> "unknown"
    end
  end

  defp get_client_peer_data(conn) do
    # Use remote_ip which is always available in Plug.Conn
    %{address: conn.remote_ip}
  end

  defp handle_rate_limited(conn, message, nil) do
    # Return JSON error for API requests or HTML error for web requests
    case get_req_header(conn, "accept") do
      [accept_header | _] when is_binary(accept_header) ->
        if String.contains?(accept_header, "application/json") do
          conn
          |> put_status(:too_many_requests)
          |> json(%{error: message})
        else
          conn
          |> put_status(:too_many_requests)
          |> put_view(SecureAuthWeb.ErrorHTML)
          |> render("429.html", message: message)
        end

      _ ->
        conn
        |> put_status(:too_many_requests)
        |> put_view(SecureAuthWeb.ErrorHTML)
        |> render("429.html", message: message)
    end
  end

  defp handle_rate_limited(conn, message, redirect_to) do
    # Redirect with flash message
    conn
    |> put_flash(:error, message)
    |> redirect(to: redirect_to)
  end

  defp get_limit(:login), do: 5
  defp get_limit(:registration), do: 3
  defp get_limit(:two_fa), do: 10
  defp get_limit(:magic_link), do: 3
  defp get_limit(_), do: 10

  @doc """
  Helper function to reset rate limit for successful actions.
  Call this after successful login, registration, etc.
  """
  def reset_rate_limit(conn, action) do
    identifier = get_identifier(conn)
    RateLimiter.reset_rate_limit(identifier, action)
    conn
  end

  @doc """
  Helper function to check rate limit status without incrementing.
  Useful for displaying remaining attempts to users.
  """
  def get_rate_limit_status(conn, action) do
    identifier = get_identifier(conn)
    RateLimiter.get_rate_limit_status(identifier, action)
  end

  @doc """
  Plug for login rate limiting
  """
  def rate_limit_login(conn, _opts) do
    call(conn, %{
      action: :login,
      message: "Too many login attempts. Please try again in 15 minutes.",
      redirect_to: "/users/log-in"
    })
  end

  @doc """
  Plug for registration rate limiting
  """
  def rate_limit_registration(conn, _opts) do
    call(conn, %{
      action: :registration,
      message: "Too many registration attempts. Please try again in 10 minutes.",
      redirect_to: "/users/register"
    })
  end

  @doc """
  Plug for 2FA rate limiting
  """
  def rate_limit_two_fa(conn, _opts) do
    call(conn, %{
      action: :two_fa,
      message: "Too many 2FA attempts. Please try again in 5 minutes.",
      redirect_to: "/users/log-in"
    })
  end

  @doc """
  Plug for magic link rate limiting
  """
  def rate_limit_magic_link(conn, _opts) do
    call(conn, %{
      action: :magic_link,
      message: "Too many magic link requests. Please try again in 10 minutes.",
      redirect_to: "/users/log-in"
    })
  end
end
