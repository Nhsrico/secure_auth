defmodule SecureAuthWeb.UserLive.Registration do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts
  alias SecureAuth.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-2xl">
        <.header class="text-center mb-8">
          Create Your Secure Account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-blue-600 hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <div class="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
          <!-- Security Notice -->
          <div class="mb-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <div class="flex items-start">
              <.icon name="hero-shield-check" class="w-5 h-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
              <div class="text-sm text-blue-800">
                <p class="font-medium mb-1">Secure Registration</p>
                <p>
                  All sensitive information is encrypted and stored securely. We require identity verification for enhanced security.
                </p>
              </div>
            </div>
          </div>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-6"
          >
            <!-- Personal Information -->
            <div class="space-y-4">
              <h3 class="text-lg font-semibold text-gray-900">Personal Information</h3>

              <.input
                field={@form[:name]}
                type="text"
                label="Full Name"
                placeholder="John Doe"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                phx-mounted={JS.focus()}
              />

              <.input
                field={@form[:email]}
                type="email"
                label="Email Address"
                placeholder="you@example.com"
                autocomplete="username"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />

              <.input
                field={@form[:phone_number]}
                type="tel"
                label="Phone Number (for 2FA)"
                placeholder="+1234567890"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />

              <.input
                field={@form[:password]}
                type="password"
                label="Password (minimum 12 characters)"
                placeholder="••••••••••••"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />
            </div>
            
    <!-- Identity Verification -->
            <div class="space-y-4">
              <h3 class="text-lg font-semibold text-gray-900">Identity Verification</h3>
              <p class="text-sm text-gray-600">Provide either SSN or passport number (not both)</p>

              <.input
                field={@form[:ssn]}
                type="text"
                label="Social Security Number (XXX-XX-XXXX)"
                placeholder="123-45-6789"
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />

              <div class="text-center text-gray-500 font-medium">OR</div>

              <.input
                field={@form[:passport_number]}
                type="text"
                label="Passport Number"
                placeholder="A12345678"
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />

              <.input
                field={@form[:next_of_kin_passport]}
                type="text"
                label="Next of Kin Passport Number"
                placeholder="B87654321"
                required
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />
            </div>

            <button
              type="submit"
              phx-disable-with="Creating account..."
              class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
            >
              Create Secure Account
            </button>
          </.form>
        </div>
        
    <!-- Privacy Notice -->
        <div class="mt-6 text-center text-sm text-gray-500">
          By registering, you agree to our secure data handling practices.
          <br />All sensitive information is encrypted and stored securely.
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: SecureAuthWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Account created successfully! An email was sent to #{user.email} to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
