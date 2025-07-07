defmodule SecureAuth.Repo.Migrations.AddOauth2FieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # OAuth2 provider fields
      add :oauth_providers, :map, default: %{}
      add :google_id, :string
      add :github_id, :string
      add :microsoft_id, :string

      # OAuth2 tokens (encrypted)
      add :oauth_tokens_encrypted, :binary

      # OAuth2 metadata
      add :oauth_email_verified, :boolean, default: false
      add :oauth_avatar_url, :string
      add :oauth_first_login, :utc_datetime
      add :oauth_last_login, :utc_datetime
    end

    # Indexes for OAuth2 lookups
    create index(:users, [:google_id])
    create index(:users, [:github_id])
    create index(:users, [:microsoft_id])
    create index(:users, [:oauth_email_verified])
    create index(:users, [:oauth_first_login])
  end
end
