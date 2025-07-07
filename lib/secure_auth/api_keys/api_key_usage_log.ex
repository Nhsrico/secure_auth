defmodule SecureAuth.ApiKeys.ApiKeyUsageLog do
  use Ecto.Schema
  import Ecto.Changeset

  alias SecureAuth.ApiKeys.ApiKey

  schema "api_key_usage_logs" do
    field :ip_address, :string
    field :user_agent, :string
    field :endpoint, :string
    field :method, :string
    field :status_code, :integer
    field :response_time_ms, :integer
    field :request_size_bytes, :integer
    field :response_size_bytes, :integer
    field :metadata, :map, default: %{}

    belongs_to :api_key, ApiKey

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Changeset for creating a new usage log entry
  """
  def creation_changeset(usage_log, attrs) do
    usage_log
    |> cast(attrs, [
      :api_key_id,
      :ip_address,
      :user_agent,
      :endpoint,
      :method,
      :status_code,
      :response_time_ms,
      :request_size_bytes,
      :response_size_bytes,
      :metadata
    ])
    |> validate_required([:api_key_id, :ip_address, :endpoint, :method, :status_code])
    |> validate_inclusion(:method, ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"])
    |> validate_number(:status_code, greater_than_or_equal_to: 100, less_than: 600)
    |> validate_number(:response_time_ms, greater_than_or_equal_to: 0)
    |> validate_number(:request_size_bytes, greater_than_or_equal_to: 0)
    |> validate_number(:response_size_bytes, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:api_key_id)
  end
end
