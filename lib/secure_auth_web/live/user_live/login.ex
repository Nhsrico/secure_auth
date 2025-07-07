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
              <.link
                navigate={~p"/users/register"}
                class="font-semibold text-blue-600 hover:underline"
              >
                Sign up
              </.link>
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
                <.link
                  href={~p"/users/register"}
                  class="text-sm font-semibold text-blue-600 hover:underline"
                >
                  Forgot your password?
                </.link>
              </div>

              <button
                type="submit"
                class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                phx-disable-with="Logging in..."
              >
                Log in
              </button>
            </.form>
            
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
                <.form for={@form} id="magic_link_form" phx-submit="send_magic_link" class="space-y-4">
                  <.input
                    field={@form[:email]}
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
     |> assign_totp_form()
     |> assign_backup_form(), temporary_assigns: [form: form]}
  end

  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
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
