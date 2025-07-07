defmodule SecureAuthWeb.Plugs.ApiAuthPlug do
  @moduledoc """
  Plug for authenticating API requests using API keys.
  Integrates with rate limiting and usage tracking.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias SecureAuth.ApiKeys
  alias SecureAuth.RateLimiter

  def init(opts) do
    scope = Keyword.get(opts, :scope, "read")
    %{required_scope: scope}
  end

  def call(conn, %{required_scope: required_scope}) do
    with {:ok, api_key} <- extract_api_key(conn),
         {:ok, user, key} <- ApiKeys.authenticate_api_key(api_key, get_client_ip(conn)),
         :ok <- check_scope(key, required_scope),
         {:ok, _remaining} <- check_rate_limit(key, get_client_ip(conn)) do
      # Update usage statistics
      ApiKeys.update_api_key_usage(key, get_client_ip(conn))

      # Log the request
      log_api_usage(key, conn)

      conn
      |> assign(:current_user, user)
      |> assign(:current_api_key, key)
      |> put_resp_header("x-api-key-remaining", to_string(key.rate_limit_per_minute))
    else
      {:error, :missing_key} ->
        send_api_error(conn, 401, "API key required")

      {:error, :invalid_key} ->
        send_api_error(conn, 401, "Invalid API key")

      {:error, :expired_key} ->
        send_api_error(conn, 401, "API key has expired")

      {:error, :ip_not_allowed} ->
        send_api_error(conn, 403, "IP address not allowed for this API key")

      {:error, :insufficient_scope} ->
        send_api_error(conn, 403, "Insufficient API key permissions")

      {:error, :rate_limited, retry_after_ms} ->
        retry_after_seconds = div(retry_after_ms, 1000)

        conn
        |> put_resp_header("retry-after", to_string(retry_after_seconds))
        |> send_api_error(429, "Rate limit exceeded")
    end
  end

  defp extract_api_key(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> api_key] ->
        {:ok, api_key}

      _ ->
        case conn.params do
          %{"api_key" => api_key} when is_binary(api_key) -> {:ok, api_key}
          _ -> {:error, :missing_key}
        end
    end
  end

  defp check_scope(api_key, required_scope) do
    case {api_key.scope, required_scope} do
      {"admin", _} -> :ok
      {"write", scope} when scope in ["read", "write"] -> :ok
      {"read", "read"} -> :ok
      _ -> {:error, :insufficient_scope}
    end
  end

  defp check_rate_limit(api_key, client_ip) do
    identifier = "api_key:#{api_key.id}:#{client_ip}"

    # Use the API key's specific rate limit
    case RateLimiter.check_rate_limit(identifier, :api_usage) do
      {:ok, remaining} -> {:ok, remaining}
      {:error, :rate_limited, retry_after_ms} -> {:error, :rate_limited, retry_after_ms}
    end
  end

  defp get_client_ip(conn) do
    case get_peer_data(conn) do
      %{address: {a, b, c, d}} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> "unknown"
    end
  end

  defp get_peer_data(conn) do
    %{address: conn.remote_ip}
  end

  defp log_api_usage(api_key, conn) do
    usage_attrs = %{
      ip_address: get_client_ip(conn),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      endpoint: conn.request_path,
      method: conn.method,
      # Will be updated later if needed
      status_code: 200,
      metadata: %{
        query_params: conn.query_params,
        path_params: conn.path_params
      }
    }

    ApiKeys.log_api_key_usage(api_key, usage_attrs)
  end

  defp send_api_error(conn, status, message) do
    conn
    |> put_status(status)
    |> put_resp_content_type("application/json")
    |> json(%{error: message, status: status})
    |> halt()
  end

  @doc """
  Plug for read-only API access
  """
  def require_read_access(conn, _opts) do
    call(conn, %{required_scope: "read"})
  end

  @doc """
  Plug for write API access
  """
  def require_write_access(conn, _opts) do
    call(conn, %{required_scope: "write"})
  end

  @doc """
  Plug for admin API access
  """
  def require_admin_access(conn, _opts) do
    call(conn, %{required_scope: "admin"})
  end
end
