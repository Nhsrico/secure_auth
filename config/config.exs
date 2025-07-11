# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :secure_auth, :scopes,
  user: [
    default: true,
    module: SecureAuth.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: SecureAuth.AccountsFixtures,
    test_login_helper: :register_and_log_in_user
  ]

config :secure_auth,
  ecto_repos: [SecureAuth.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :secure_auth, SecureAuthWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SecureAuthWeb.ErrorHTML, json: SecureAuthWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SecureAuth.PubSub,
  live_view: [signing_salt: "qgd2K15U"]

# OAuth2 Configuration
# Note: These are placeholder values for development
# In production, set these via environment variables
config :ueberauth, Ueberauth,
  providers: [
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "email profile",
         prompt: "consent",
         access_type: "offline"
       ]},
    github:
      {Ueberauth.Strategy.Github,
       [
         default_scope: "user:email"
       ]},
    microsoft:
      {Ueberauth.Strategy.Microsoft,
       [
         default_scope: "https://graph.microsoft.com/user.read"
       ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID", "your-google-client-id"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET", "your-google-client-secret")

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID", "your-github-client-id"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET", "your-github-client-secret")

config :ueberauth, Ueberauth.Strategy.Microsoft.OAuth,
  client_id: System.get_env("MICROSOFT_CLIENT_ID", "your-microsoft-client-id"),
  client_secret: System.get_env("MICROSOFT_CLIENT_SECRET", "your-microsoft-client-secret"),
  tenant_id: System.get_env("MICROSOFT_TENANT_ID", "common")

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  secure_auth: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  secure_auth: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
