defmodule SecureAuthWeb.UserLive.Verify2FA do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-2xl">
        <.header class="text-center mb-8">
          Two-Factor Authentication
          <:subtitle>
            Enter the 6-digit code from your authenticator app
          </:subtitle>
        </.header>

        <div class="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
          <%= if @pending_user do %>
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
          <% else %>
            <!-- No pending user session -->
            <div class="text-center">
              <.icon name="hero-exclamation-triangle" class="w-12 h-12 text-red-500 mx-auto mb-4" />
              <h3 class="text-lg font-semibold text-gray-900 mb-2">Session Expired</h3>
              <p class="text-gray-600 mb-6">
                Your authentication session has expired. Please log in again.
              </p>
              <.link
                navigate={~p"/users/log-in"}
                class="inline-block bg-blue-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors"
              >
                Return to Login
              </.link>
            </div>
          <% end %>
          
    <!-- Return to Login -->
          <%= if @pending_user do %>
            <div class="mt-6 text-center">
              <.link
                navigate={~p"/users/log-in"}
                class="text-sm text-gray-600 hover:text-gray-800 transition-colors"
              >
                ← Return to login
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, session, socket) do
    pending_user_id = Map.get(session, "pending_user_id")

    pending_user =
      if pending_user_id do
        Accounts.get_user!(pending_user_id)
      else
        nil
      end

    if pending_user && pending_user.two_factor_enabled do
      {:ok,
       socket
       |> assign(:pending_user, pending_user)
       |> assign(:show_backup_form, false)
       |> assign_totp_form()
       |> assign_backup_form()}
    else
      {:ok,
       socket
       |> assign(:pending_user, nil)
       |> assign(:show_backup_form, false)
       |> assign_totp_form()
       |> assign_backup_form()}
    end
  end

  def handle_event("verify_totp", %{"user" => %{"totp_code" => code}}, socket) do
    user = socket.assigns.pending_user

    if user && Accounts.verify_totp(user, code) do
      # Generate session token and redirect to complete login
      token = Accounts.generate_user_session_token(user)

      {:noreply,
       socket
       |> put_flash(:info, "Welcome back!")
       |> redirect(external: "/users/log-in?user_token=#{token}")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid authentication code. Please try again.")
       |> assign_totp_form()}
    end
  end

  def handle_event("verify_backup_code", %{"user" => %{"backup_code" => code}}, socket) do
    user = socket.assigns.pending_user

    if user && Accounts.verify_backup_code(user, code) do
      # Generate session token and redirect to complete login
      token = Accounts.generate_user_session_token(user)

      {:noreply,
       socket
       |> put_flash(:info, "Welcome back! You used a backup code.")
       |> redirect(external: "/users/log-in?user_token=#{token}")}
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

  defp assign_totp_form(socket) do
    form = to_form(%{}, as: "user")
    assign(socket, totp_form: form)
  end

  defp assign_backup_form(socket) do
    form = to_form(%{}, as: "user")
    assign(socket, backup_form: form)
  end
end
