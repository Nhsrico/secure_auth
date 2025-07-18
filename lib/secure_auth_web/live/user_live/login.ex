defmodule SecureAuthWeb.UserLive.Login do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-2xl">
        <%= if @step == :login do %>
          <!-- Email/Password Login Step -->
          <.header class="text-center mb-8">
            Log in to your account
            <:subtitle>
              Don't have an account?
              <a navigate={~p"/users/register"} class="font-semibold text-blue-600 hover:underline">
                Sign up
              </a>
              for an account now.
            </:subtitle>
          </.header>

          <div class="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
            <.form
              for={@form}
              id="login_form"
              action={~p"/users/log-in"}
              phx-update="ignore"
              class="space-y-6"
            >
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                placeholder="you@example.com"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                phx-mounted={JS.focus()}
              />

              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                placeholder="••••••••••••"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />

              <div class="flex items-center justify-between">
                <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
                <a
                  href={~p"/users/reset-password"}
                  class="text-sm font-semibold text-blue-600 hover:underline"
                >
                  Forgot your password?
                </a>
              </div>

              <button
                type="submit"
                class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                phx-disable-with="Logging in..."
              >
                Log in
              </button>
            </.form>
            
    <!-- OAuth2 Login Options -->
            <div class="mt-6">
              <div class="relative">
                <div class="absolute inset-0 flex items-center">
                  <div class="w-full border-t border-gray-300"></div>
                </div>
                <div class="relative flex justify-center text-sm">
                  <span class="px-2 bg-white text-gray-500">Or sign in with</span>
                </div>
              </div>

              <div class="mt-6 grid grid-cols-1 gap-3">
                <a
                  href="/auth/google"
                  class="w-full inline-flex justify-center py-3 px-4 border border-gray-300 rounded-lg shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 transition-colors"
                >
                  <svg class="w-5 h-5 mr-2" viewBox="0 0 24 24">
                    <path
                      fill="#4285F4"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="#34A853"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    />
                    <path
                      fill="#EA4335"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    />
                  </svg>
                  Continue with Google
                </a>
                <a
                  href="/auth/github"
                  class="w-full inline-flex justify-center py-3 px-4 border border-gray-300 rounded-lg shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 transition-colors"
                >
                  <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                  </svg>
                  Continue with GitHub
                </a>
                <a
                  href="/auth/microsoft"
                  class="w-full inline-flex justify-center py-3 px-4 border border-gray-300 rounded-lg shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 transition-colors"
                >
                  <svg class="w-5 h-5 mr-2" viewBox="0 0 24 24">
                    <path fill="#F25022" d="M1 1h10v10H1z" />
                    <path fill="#00A4EF" d="M13 1h10v10H13z" />
                    <path fill="#7FBA00" d="M1 13h10v10H1z" />
                    <path fill="#FFB900" d="M13 13h10v10H13z" />
                  </svg>
                  Continue with Microsoft
                </a>
              </div>
            </div>
            
    <!-- Magic Link Option -->
            <div class="mt-6 text-center">
              <div class="relative">
                <div class="absolute inset-0 flex items-center">
                  <div class="w-full border-t border-gray-300"></div>
                </div>
                <div class="relative flex justify-center text-sm">
                  <span class="px-2 bg-white text-gray-500">Or continue with</span>
                </div>
              </div>
              <div class="mt-6">
                <.form
                  for={@magic_link_form}
                  id="magic_link_form"
                  phx-submit="send_magic_link"
                  class="space-y-4"
                >
                  <.input
                    field={@magic_link_form[:email]}
                    type="email"
                    label="Email for magic link"
                    placeholder="you@example.com"
                    class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                  />
                  <button
                    type="submit"
                    class="w-full bg-gray-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-gray-700 transition-colors"
                    phx-disable-with="Sending..."
                  >
                    Send Magic Link
                  </button>
                </.form>
              </div>
            </div>
          </div>
        <% else %>
          <!-- 2FA Verification Step -->
          <.header class="text-center mb-8">
            Two-Factor Authentication
            <:subtitle>
              Enter the 6-digit code from your authenticator app
            </:subtitle>
          </.header>

          <div class="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
            <!-- User Email Display -->
            <div class="mb-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
              <div class="flex items-center">
                <.icon name="hero-user" class="w-5 h-5 text-blue-600 mr-3" />
                <div class="text-sm text-blue-800">
                  <p class="font-medium">Logging in as:</p>
                  <p>{@pending_user.email}</p>
                </div>
              </div>
            </div>
            
    <!-- TOTP Code Form -->
            <.form
              for={@totp_form}
              id="totp-verification-form"
              phx-submit="verify_totp"
              class="space-y-6"
            >
              <.input
                field={@totp_form[:totp_code]}
                type="text"
                label="Authentication Code"
                placeholder="123456"
                maxlength="6"
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white text-center text-2xl font-mono tracking-widest"
                phx-mounted={JS.focus()}
              />
              <button
                type="submit"
                class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                phx-disable-with="Verifying..."
              >
                Verify and Log In
              </button>
            </.form>
            
    <!-- Backup Code Option -->
            <div class="mt-6">
              <%= if @show_backup_form do %>
                <.form
                  for={@backup_form}
                  id="backup-code-form"
                  phx-submit="verify_backup_code"
                  class="space-y-4"
                >
                  <.input
                    field={@backup_form[:backup_code]}
                    type="text"
                    label="Backup Recovery Code"
                    placeholder="abc123def456"
                    class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white text-center font-mono"
                  />
                  <button
                    type="submit"
                    class="w-full bg-gray-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-gray-700 transition-colors"
                    phx-disable-with="Verifying..."
                  >
                    Use Backup Code
                  </button>
                  <button
                    type="button"
                    phx-click="hide_backup_form"
                    class="w-full text-gray-600 hover:text-gray-800 transition-colors"
                  >
                    Cancel
                  </button>
                </.form>
              <% else %>
                <div class="text-center">
                  <button
                    type="button"
                    phx-click="show_backup_form"
                    class="text-sm text-blue-600 hover:text-blue-500 transition-colors"
                  >
                    Lost your device? Use a backup code instead
                  </button>
                </div>
              <% end %>
            </div>
            
    <!-- Return to Login -->
            <div class="mt-6 text-center">
              <button
                type="button"
                phx-click="return_to_login"
                class="text-sm text-gray-600 hover:text-gray-800 transition-colors"
              >
                ← Return to login
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: SecureAuthWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     socket
     |> assign(:step, :login)
     |> assign(:pending_user, nil)
     |> assign(:show_backup_form, false)
     |> assign_form(form)
     |> assign(:magic_link_form, to_form(%{}, as: "magic_link"))
     |> assign_totp_form()
     |> assign_backup_form(), temporary_assigns: [form: form]}
  end

  def handle_event("send_magic_link", %{"magic_link" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to log in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  def handle_event("verify_totp", %{"user" => %{"totp_code" => code}}, socket) do
    user = socket.assigns.pending_user

    if Accounts.verify_totp(user, code) do
      # Complete the login process
      token = Accounts.generate_user_session_token(user)

      {:noreply,
       socket
       |> put_flash(:info, "Welcome back!")
       |> redirect(to: ~p"/users/log-in?user_token=#{token}")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid authentication code. Please try again.")
       |> assign_totp_form()}
    end
  end

  def handle_event("verify_backup_code", %{"user" => %{"backup_code" => code}}, socket) do
    user = socket.assigns.pending_user

    if Accounts.verify_backup_code(user, code) do
      # Complete the login process
      token = Accounts.generate_user_session_token(user)

      {:noreply,
       socket
       |> put_flash(:info, "Welcome back! You used a backup code.")
       |> redirect(to: ~p"/users/log-in?user_token=#{token}")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid backup code. Please try again.")
       |> assign_backup_form()}
    end
  end

  def handle_event("show_backup_form", _params, socket) do
    {:noreply, assign(socket, :show_backup_form, true)}
  end

  def handle_event("hide_backup_form", _params, socket) do
    {:noreply, assign(socket, :show_backup_form, false)}
  end

  def handle_event("return_to_login", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :login)
     |> assign(:pending_user, nil)
     |> assign(:show_backup_form, false)}
  end

  defp assign_form(socket, %Phoenix.HTML.Form{} = form) do
    assign(socket, form: form)
  end

  defp assign_form(socket, params) do
    form = to_form(params, as: "user")
    assign(socket, form: form)
  end

  defp assign_totp_form(socket) do
    form = to_form(%{}, as: "user")
    assign(socket, totp_form: form)
  end

  defp assign_backup_form(socket) do
    form = to_form(%{}, as: "user")
    assign(socket, backup_form: form)
  end
end
