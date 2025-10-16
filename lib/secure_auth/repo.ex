defmodule SecureAuth.Repo do
  use Ecto.Repo,
    otp_app: :secure_auth,
    # If you want to hardcode the adapter for all envs, uncomment one:
    adapter: Ecto.Adapters.SQLite3
    # adapter: Ecto.Adapters.Postgres
end
