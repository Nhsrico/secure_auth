defmodule SecureAuthWeb.Router do
  use SecureAuthWeb, :router

  import SecureAuthWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SecureAuthWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug SecureAuthWeb.Plugs.ApiAuthPlug, scope: "read"
  end

  scope "/", SecureAuthWeb do
    pipe_through :browser

    live "/", UserLive.Dashboard, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", SecureAuthWeb do
    pipe_through :api
    get "/test", Api.TestController, :index
    get "/test/:id", Api.TestController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:secure_auth, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SecureAuthWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SecureAuthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SecureAuthWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/users/two-factor-setup", UserLive.TwoFactorSetup, :new
      live "/dashboard", UserLive.Dashboard, :index
      live "/admin/security", AdminLive.SecurityDashboard, :index
      live "/api-keys", ApiKeysLive.Index, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", SecureAuthWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{SecureAuthWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/users/verify-2fa", UserLive.Verify2FA, :new
      live "/users/reset-password", UserLive.ResetPassword, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
    get "/auth/:provider", OAuth2Controller, :request
    get "/auth/:provider/callback", OAuth2Controller, :callback
  end
end
