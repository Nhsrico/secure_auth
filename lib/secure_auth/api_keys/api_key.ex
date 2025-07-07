defmodule SecureAuth.ApiKeys.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  alias SecureAuth.Accounts.User
  alias SecureAuth.ApiKeys.ApiKeyUsageLog

  @scopes ["read", "write", "admin"]
  @key_length 64

  schema "api_keys" do
    field :name, :string
    field :key_hash, :string
    field :key_prefix, :string
    field :scope, :string, default: "read"
    field :expires_at, :utc_datetime
    field :last_used_at, :utc_datetime
    field :last_used_ip, :string
    field :request_count, :integer, default: 0
    field :is_active, :boolean, default: true
    field :ip_whitelist, {:array, :string}
    field :rate_limit_per_minute, :integer, default: 60
    field :description, :string
    field :metadata, :map, default: %{}

    # Virtual fields
    field :raw_key, :string, virtual: true

    belongs_to :user, User
    has_many :usage_logs, ApiKeyUsageLog, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new API key
  """
  def creation_changeset(api_key, attrs, user) do
    api_key
    |> cast(attrs, [
      :name,
      :scope,
      :expires_at,
      :ip_whitelist,
      :rate_limit_per_minute,
      :description,
      :metadata
    ])
    |> validate_required([:name, :scope])
    |> validate_inclusion(:scope, @scopes)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_number(:rate_limit_per_minute, greater_than: 0, less_than_or_equal_to: 10000)
    |> validate_expires_at()
    |> validate_ip_whitelist()
    |> put_assoc(:user, user)
    |> unique_constraint([:user_id, :name], message: "You already have an API key with this name")
    |> generate_api_key()
  end

  @doc """
  Changeset for updating an API key
  """
  def update_changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [
      :name,
      :expires_at,
      :ip_whitelist,
      :rate_limit_per_minute,
      :description,
      :metadata,
      :is_active
    ])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_number(:rate_limit_per_minute, greater_than: 0, less_than_or_equal_to: 10000)
    |> validate_expires_at()
    |> validate_ip_whitelist()
    |> unique_constraint([:user_id, :name], message: "You already have an API key with this name")
  end

  @doc """
  Changeset for updating usage statistics
  """
  def usage_changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:last_used_at, :last_used_ip, :request_count])
    |> validate_required([:last_used_at])
  end

  @doc """
  Generate a secure API key and hash it for storage
  """
  def generate_key do
    key = :crypto.strong_rand_bytes(@key_length) |> Base.url_encode64(padding: false)
    prefix = String.slice(key, 0, 8)
    hash = :crypto.hash(:sha256, key) |> Base.encode64()

    {key, prefix, hash}
  end

  @doc """
  Verify an API key against its hash
  """
  def verify_key(raw_key, key_hash) when is_binary(raw_key) and is_binary(key_hash) do
    computed_hash = :crypto.hash(:sha256, raw_key) |> Base.encode64()
    computed_hash == key_hash
  end

  @doc """
  Check if an API key has expired
  """
  def expired?(%__MODULE__{expires_at: nil}), do: false

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Check if an API key is valid for use
  """
  def valid?(%__MODULE__{is_active: false}), do: false
  def valid?(api_key), do: not expired?(api_key)

  @doc """
  Check if an IP address is whitelisted for this API key
  """
  def ip_allowed?(%__MODULE__{ip_whitelist: nil}, _ip), do: true
  def ip_allowed?(%__MODULE__{ip_whitelist: []}, _ip), do: true

  def ip_allowed?(%__MODULE__{ip_whitelist: whitelist}, ip) do
    ip in whitelist
  end

  @doc """
  Get available scopes
  """
  def scopes, do: @scopes

  # Private functions

  defp generate_api_key(changeset) do
    if changeset.valid? do
      {raw_key, prefix, hash} = generate_key()

      changeset
      |> put_change(:raw_key, raw_key)
      |> put_change(:key_prefix, prefix)
      |> put_change(:key_hash, hash)
    else
      changeset
    end
  end

  defp validate_expires_at(changeset) do
    case get_change(changeset, :expires_at) do
      nil ->
        changeset

      expires_at ->
        if DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
          changeset
        else
          add_error(changeset, :expires_at, "must be in the future")
        end
    end
  end

  defp validate_ip_whitelist(changeset) do
    case get_change(changeset, :ip_whitelist) do
      nil ->
        changeset

      [] ->
        changeset

      ips when is_list(ips) ->
        if Enum.all?(ips, &valid_ip?/1) do
          changeset
        else
          add_error(changeset, :ip_whitelist, "contains invalid IP addresses")
        end

      _ ->
        add_error(changeset, :ip_whitelist, "must be a list of IP addresses")
    end
  end

  defp valid_ip?(ip) when is_binary(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp valid_ip?(_), do: false
end
