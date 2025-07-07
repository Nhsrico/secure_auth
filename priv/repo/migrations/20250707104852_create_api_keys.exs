defmodule SecureAuth.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :key_hash, :string, null: false
      add :key_prefix, :string, null: false
      add :scope, :string, null: false, default: "read"
      add :expires_at, :utc_datetime
      add :last_used_at, :utc_datetime
      add :last_used_ip, :string
      add :request_count, :integer, default: 0, null: false
      add :is_active, :boolean, default: true, null: false
      add :ip_whitelist, {:array, :string}
      add :rate_limit_per_minute, :integer, default: 60
      add :description, :text
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:api_keys, [:user_id])
    create index(:api_keys, [:key_prefix])
    create index(:api_keys, [:scope])
    create index(:api_keys, [:is_active])
    create index(:api_keys, [:expires_at])
    create index(:api_keys, [:last_used_at])
    create unique_index(:api_keys, [:key_hash])
    create unique_index(:api_keys, [:user_id, :name])

    # Create API key usage logs table for detailed analytics
    create table(:api_key_usage_logs) do
      add :api_key_id, references(:api_keys, on_delete: :delete_all), null: false
      add :ip_address, :string, null: false
      add :user_agent, :string
      add :endpoint, :string, null: false
      add :method, :string, null: false
      add :status_code, :integer, null: false
      add :response_time_ms, :integer
      add :request_size_bytes, :integer
      add :response_size_bytes, :integer
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:api_key_usage_logs, [:api_key_id])
    create index(:api_key_usage_logs, [:ip_address])
    create index(:api_key_usage_logs, [:inserted_at])
    create index(:api_key_usage_logs, [:endpoint])
    create index(:api_key_usage_logs, [:status_code])
  end
end
