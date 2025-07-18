import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/secure_auth start
#
# Alternatively, you can use `mix phx.server` or set the RELEASE_NODE
# environment variable to "remote" to start a remote shell.

# Start the phoenix server if environment variable is set
if System.get_env("PHX_SERVER") do
  config :secure_auth, SecureAuthWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :secure_auth, SecureAuth.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :secure_auth, SecureAuthWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopbacks vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure the mailer
  sendgrid_api_key = System.get_env("SENDGRID_API_KEY")
  mailer_adapter = System.get_env("MAILER_ADAPTER")

  cond do
    mailer_adapter == "local" ->
      # Use local adapter for testing - logs emails instead of sending them
      config :secure_auth, SecureAuth.Mailer, adapter: Swoosh.Adapters.Local

    is_binary(sendgrid_api_key) and sendgrid_api_key != "" ->
      # Use SendGrid when API key is available
      config :secure_auth, SecureAuth.Mailer,
        adapter: Swoosh.Adapters.Sendgrid,
        api_key: sendgrid_api_key

    true ->
      # Fallback to local adapter if no proper configuration
      config :secure_auth, SecureAuth.Mailer, adapter: Swoosh.Adapters.Local
  end
end
