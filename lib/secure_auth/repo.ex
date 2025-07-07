defmodule SecureAuth.Repo do
  use Ecto.Repo,
    otp_app: :secure_auth,
    adapter: Ecto.Adapters.SQLite3
end
