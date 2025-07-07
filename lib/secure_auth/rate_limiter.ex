defmodule SecureAuth.RateLimiter do
  @moduledoc """
  Simple but effective rate limiter using ETS for tracking requests.
  Supports different rate limiting strategies and automatic cleanup.
  """

  use GenServer
  require Logger

  @table_name :rate_limiter_requests
  @cleanup_interval :timer.minutes(5)

  # Rate limiting configurations
  @login_attempts %{limit: 5, window: :timer.minutes(15)}
  @registration_attempts %{limit: 3, window: :timer.minutes(10)}
  @two_fa_attempts %{limit: 10, window: :timer.minutes(5)}
  @magic_link_requests %{limit: 3, window: :timer.minutes(10)}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Check if request is allowed for the given identifier and action.
  Returns {:ok, remaining} or {:error, :rate_limited, retry_after_ms}
  """
  def check_rate_limit(identifier, action) when is_binary(identifier) and is_atom(action) do
    config = get_config(action)
    key = {identifier, action}
    now = System.system_time(:millisecond)
    window_start = now - config.window

    # Clean old entries for this key
    cleanup_old_entries(key, window_start)

    # Count current requests in window
    current_count = count_requests(key, window_start)

    if current_count >= config.limit do
      # Calculate retry after time
      oldest_request = get_oldest_request(key)

      retry_after =
        if oldest_request, do: oldest_request + config.window - now, else: config.window

      {:error, :rate_limited, max(retry_after, 0)}
    else
      # Record this request
      :ets.insert(@table_name, {key, now})
      remaining = config.limit - current_count - 1
      {:ok, remaining}
    end
  end

  @doc """
  Reset rate limit for a specific identifier and action.
  Useful for successful authentication after failed attempts.
  """
  def reset_rate_limit(identifier, action) when is_binary(identifier) and is_atom(action) do
    key = {identifier, action}
    :ets.match_delete(@table_name, {key, :_})
    :ok
  end

  @doc """
  Get current rate limit status without incrementing counter.
  Returns {:ok, remaining, resets_in_ms} or {:error, :rate_limited, retry_after_ms}
  """
  def get_rate_limit_status(identifier, action) when is_binary(identifier) and is_atom(action) do
    config = get_config(action)
    key = {identifier, action}
    now = System.system_time(:millisecond)
    window_start = now - config.window

    # Clean old entries for this key
    cleanup_old_entries(key, window_start)

    # Count current requests in window
    current_count = count_requests(key, window_start)

    if current_count >= config.limit do
      oldest_request = get_oldest_request(key)

      retry_after =
        if oldest_request, do: oldest_request + config.window - now, else: config.window

      {:error, :rate_limited, max(retry_after, 0)}
    else
      oldest_request = get_oldest_request(key)
      resets_in = if oldest_request, do: oldest_request + config.window - now, else: config.window
      remaining = config.limit - current_count
      {:ok, remaining, max(resets_in, 0)}
    end
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for storing rate limit data
    :ets.new(@table_name, [:named_table, :public, :duplicate_bag])

    # Schedule periodic cleanup
    schedule_cleanup()

    Logger.info("RateLimiter started with ETS table: #{@table_name}")
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  # Private functions

  defp get_config(:login), do: @login_attempts
  defp get_config(:registration), do: @registration_attempts
  defp get_config(:two_fa), do: @two_fa_attempts
  defp get_config(:magic_link), do: @magic_link_requests
  defp get_config(_), do: %{limit: 10, window: :timer.minutes(5)}

  defp count_requests(key, window_start) do
    :ets.select_count(@table_name, [
      {{key, :"$1"}, [{:>=, :"$1", window_start}], [true]}
    ])
  end

  defp get_oldest_request(key) do
    case :ets.select(@table_name, [{{key, :"$1"}, [], [:"$1"]}]) do
      [] -> nil
      timestamps -> Enum.min(timestamps)
    end
  end

  defp cleanup_old_entries(key, window_start) do
    :ets.select_delete(@table_name, [
      {{key, :"$1"}, [{:<, :"$1", window_start}], [true]}
    ])
  end

  defp cleanup_expired_entries do
    now = System.system_time(:millisecond)
    # Clean anything older than max window
    max_window = :timer.minutes(15)
    expired_time = now - max_window

    deleted =
      :ets.select_delete(@table_name, [
        {{:_, :"$1"}, [{:<, :"$1", expired_time}], [true]}
      ])

    if deleted > 0 do
      Logger.debug("RateLimiter cleaned up #{deleted} expired entries")
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
