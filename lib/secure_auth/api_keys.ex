defmodule SecureAuth.ApiKeys do
  @moduledoc """
  The ApiKeys context.
  """

  import Ecto.Query, warn: false
  alias SecureAuth.Repo

  alias SecureAuth.ApiKeys.{ApiKey, ApiKeyUsageLog}
  alias SecureAuth.Accounts.User

  @doc """
  Returns the list of api_keys for a user.

  ## Examples

      iex> list_api_keys(user)
      [%ApiKey{}, ...]

  """
  def list_api_keys(%User{} = user) do
    from(api_key in ApiKey,
      where: api_key.user_id == ^user.id,
      order_by: [desc: api_key.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single api_key by id for a specific user.

  Raises `Ecto.NoResultsError` if the Api key does not exist.

  ## Examples

      iex> get_api_key!(user, 123)
      %ApiKey{}

      iex> get_api_key!(user, 456)
      ** (Ecto.NoResultsError)

  """
  def get_api_key!(%User{} = user, id) do
    from(api_key in ApiKey,
      where: api_key.id == ^id and api_key.user_id == ^user.id,
      preload: [:user]
    )
    |> Repo.one!()
  end

  @doc """
  Gets an api_key by its key hash for authentication.
  Returns nil if not found or invalid.
  """
  def get_api_key_by_hash(key_hash) when is_binary(key_hash) do
    from(api_key in ApiKey,
      where: api_key.key_hash == ^key_hash and api_key.is_active == true,
      preload: [:user]
    )
    |> Repo.one()
  end

  @doc """
  Authenticates an API key and returns the associated user and key.
  Performs all security checks including expiration, IP whitelist, etc.
  """
  def authenticate_api_key(raw_key, client_ip \\ nil) when is_binary(raw_key) do
    key_hash = :crypto.hash(:sha256, raw_key) |> Base.encode64()

    case get_api_key_by_hash(key_hash) do
      nil ->
        {:error, :invalid_key}

      api_key ->
        cond do
          not ApiKey.valid?(api_key) ->
            {:error, :invalid_key}

          ApiKey.expired?(api_key) ->
            {:error, :expired_key}

          client_ip && not ApiKey.ip_allowed?(api_key, client_ip) ->
            {:error, :ip_not_allowed}

          true ->
            {:ok, api_key.user, api_key}
        end
    end
  end

  @doc """
  Creates an api_key.

  ## Examples

      iex> create_api_key(user, %{field: value})
      {:ok, %ApiKey{}}

      iex> create_api_key(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_api_key(%User{} = user, attrs \\ %{}) do
    %ApiKey{}
    |> ApiKey.creation_changeset(attrs, user)
    |> Repo.insert()
  end

  @doc """
  Updates an api_key.

  ## Examples

      iex> update_api_key(api_key, %{field: new_value})
      {:ok, %ApiKey{}}

      iex> update_api_key(api_key, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_api_key(%ApiKey{} = api_key, attrs) do
    api_key
    |> ApiKey.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates api_key usage statistics.
  """
  def update_api_key_usage(%ApiKey{} = api_key, client_ip) do
    now = DateTime.utc_now()

    api_key
    |> ApiKey.usage_changeset(%{
      last_used_at: now,
      last_used_ip: client_ip,
      request_count: api_key.request_count + 1
    })
    |> Repo.update()
  end

  @doc """
  Deletes an api_key.

  ## Examples

      iex> delete_api_key(api_key)
      {:ok, %ApiKey{}}

      iex> delete_api_key(api_key)
      {:error, %Ecto.Changeset{}}

  """
  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  @doc """
  Revokes (deactivates) an api_key instead of deleting it.
  """
  def revoke_api_key(%ApiKey{} = api_key) do
    update_api_key(api_key, %{is_active: false})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking api_key changes.

  ## Examples

      iex> change_api_key(api_key)
      %Ecto.Changeset{{}}

  """
  def change_api_key(%ApiKey{} = api_key, attrs \\ %{}) do
    ApiKey.update_changeset(api_key, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for creating a new api_key.
  """
  def change_new_api_key(%User{} = user, attrs \\ %{}) do
    ApiKey.creation_changeset(%ApiKey{}, attrs, user)
  end

  @doc """
  Logs API key usage for analytics and audit purposes.
  """
  def log_api_key_usage(%ApiKey{} = api_key, usage_attrs) do
    usage_attrs = Map.put(usage_attrs, :api_key_id, api_key.id)

    %ApiKeyUsageLog{}
    |> ApiKeyUsageLog.creation_changeset(usage_attrs)
    |> Repo.insert()
  end

  @doc """
  Gets usage statistics for an API key.
  """
  def get_api_key_usage_stats(%ApiKey{} = api_key, days_back \\ 30) do
    start_date = DateTime.utc_now() |> DateTime.add(-days_back, :day)

    usage_logs =
      from(log in ApiKeyUsageLog,
        where: log.api_key_id == ^api_key.id and log.inserted_at >= ^start_date,
        order_by: [desc: log.inserted_at]
      )
      |> Repo.all()

    %{
      total_requests: length(usage_logs),
      unique_ips: usage_logs |> Enum.map(& &1.ip_address) |> Enum.uniq() |> length(),
      status_codes:
        usage_logs
        |> Enum.group_by(& &1.status_code)
        |> Enum.map(fn {code, logs} -> {code, length(logs)} end),
      daily_usage: get_daily_usage(usage_logs),
      avg_response_time: calculate_avg_response_time(usage_logs)
    }
  end

  @doc """
  Cleans up expired API keys.
  """
  def cleanup_expired_keys do
    now = DateTime.utc_now()

    from(api_key in ApiKey,
      where: not is_nil(api_key.expires_at) and api_key.expires_at < ^now
    )
    |> Repo.delete_all()
  end

  # Private functions

  defp get_daily_usage(usage_logs) do
    usage_logs
    |> Enum.group_by(fn log ->
      log.inserted_at |> DateTime.to_date() |> Date.to_string()
    end)
    |> Enum.map(fn {date, logs} -> {date, length(logs)} end)
    |> Enum.sort()
  end

  defp calculate_avg_response_time(usage_logs) do
    response_times =
      usage_logs
      |> Enum.filter(& &1.response_time_ms)
      |> Enum.map(& &1.response_time_ms)

    case response_times do
      [] -> 0
      times -> Enum.sum(times) / length(times)
    end
  end
end
