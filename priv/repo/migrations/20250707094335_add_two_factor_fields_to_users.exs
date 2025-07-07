defmodule SecureAuth.Repo.Migrations.AddTwoFactorFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :totp_secret_encrypted, :binary
      add :two_factor_enabled, :boolean, default: false, null: false
      add :backup_codes_encrypted, :binary
      add :totp_last_used_at, :utc_datetime
    end

    create index(:users, [:two_factor_enabled])
    create index(:users, [:totp_last_used_at])
  end
end
