import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.

config :secure_auth, SecureAuthWeb.Endpoint,
  url: [host: "secure-auth-prod.fly.dev", port: 443, scheme: "https"],
  check_origin: [
    "https://secure-auth-prod.fly.dev"
  ],
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: 8080],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

# Configure the database for production
config :secure_auth, SecureAuth.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: false

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: SecureAuth.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
