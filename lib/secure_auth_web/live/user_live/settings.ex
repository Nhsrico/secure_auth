defmodule SecureAuthWeb.UserLive.Settings do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header class="text-center mb-8">
          Account Settings
          <:subtitle>Manage your account information and security settings</:subtitle>
        </.header>

        <div class="space-y-8">
          <!-- Phone Number Form -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Phone Number</h3>
            <p class="text-sm text-gray-600 mb-4">
              Your phone number is used for two-factor authentication. Keep it up to date for account security.
            </p>

            <.form
              for={@phone_form}
              id="phone_form"
              phx-submit="update_phone"
              phx-change="validate_phone"
              class="space-y-4"
            >
              <.input
                field={@phone_form[:phone_number]}
                type="tel"
                label="Phone Number"
                placeholder="+1234567890"
                autocomplete="tel"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />
              <button
                type="submit"
                class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                phx-disable-with="Updating..."
              >
                Update Phone Number
              </button>
            </.form>
          </div>
          
    <!-- Email Form -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Email Address</h3>
            <p class="text-sm text-gray-600 mb-4">
              Change your email address. You'll need to confirm the new address.
            </p>

            <.form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
              class="space-y-4"
            >
              <.input
                field={@email_form[:email]}
                type="email"
                label="Email Address"
                autocomplete="username"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />
              <button
                type="submit"
                class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                phx-disable-with="Changing..."
              >
                Change Email
              </button>
            </.form>
          </div>
          
    <!-- Password Form -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Password</h3>
            <p class="text-sm text-gray-600 mb-4">
              Update your password. Choose a strong password to keep your account secure.
            </p>

            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/update-password"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
              <.input
                field={@password_form[:password]}
                type="password"
                label="New Password"
                autocomplete="new-password"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm New Password"
                autocomplete="new-password"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />
              <button
                type="submit"
                class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                phx-disable-with="Saving..."
              >
                Save Password
              </button>
            </.form>
          </div>
          
    <!-- Two-Factor Authentication Status -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-lg font-semibold text-gray-900">Two-Factor Authentication</h3>
                <p class="text-sm text-gray-600 mt-1">
                  <%= if @current_scope.user.two_factor_enabled do %>
                    Two-factor authentication is enabled and protecting your account.
                  <% else %>
                    Add an extra layer of security to your account.
                  <% end %>
                </p>
              </div>
              <div class="flex items-center space-x-3">
                <span class={"inline-flex items-center px-3 py-1 rounded-full text-sm font-medium #{if @current_scope.user.two_factor_enabled, do: "bg-green-100 text-green-700", else: "bg-yellow-100 text-yellow-700"}"}>
                  <%= if @current_scope.user.two_factor_enabled do %>
                    <.icon name="hero-shield-check" class="w-4 h-4 mr-1" /> Enabled
                  <% else %>
                    <.icon name="hero-shield-exclamation" class="w-4 h-4 mr-1" /> Disabled
                  <% end %>
                </span>
                <%= if not @current_scope.user.two_factor_enabled do %>
                  <.link
                    navigate={~p"/users/two-factor-setup"}
                    class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
                  >
                    Enable 2FA
                  </.link>
                <% end %>
              </div>
            </div>
          </div>
          
    <!-- API Keys Link -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-lg font-semibold text-gray-900">API Keys</h3>
                <p class="text-sm text-gray-600 mt-1">
                  Manage API keys for programmatic access to your account.
                </p>
              </div>
              <.link
                navigate={~p"/api-keys"}
                class="inline-flex items-center px-4 py-2 bg-gray-600 text-white rounded-lg font-medium hover:bg-gray-700 transition-colors"
              >
                <.icon name="hero-key" class="w-4 h-4 mr-2" /> Manage API Keys
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_email: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    phone_changeset = Accounts.change_user_phone(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:phone_form, to_form(phone_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_phone", params, socket) do
    %{"user" => user_params} = params

    phone_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_phone(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, phone_form: phone_form)}
  end

  def handle_event("update_phone", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.update_user_phone(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Phone number updated successfully.")
         |> assign(:phone_form, to_form(Accounts.change_user_phone(user, %{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :phone_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_email: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
