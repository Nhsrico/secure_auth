defmodule SecureAuth.Repo.Migrations.AddSecureFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string, null: false
      add :phone_number, :string, null: false
      add :ssn_encrypted, :binary
      add :passport_number_encrypted, :binary
      add :next_of_kin_passport_encrypted, :binary, null: false
      add :verification_status, :string, default: "pending", null: false
    end

    create index(:users, [:phone_number])
    create index(:users, [:verification_status])
  end
end
