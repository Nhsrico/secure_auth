defmodule SecureAuthWeb.UserLive.ResetPassword do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">
        <div class="mx-auto max-w-2xl">
          <div class="px-4 py-10 sm:px-6 lg:px-8">
            <header class="pb-4 text-center mb-8">
              <div>
                <h1 class="text-lg font-semibold leading-8">
                  Reset your password
                </h1>
                <p class="text-sm text-base-content/70">
                  Enter your email address and we'll send you a link to reset your password.
                </p>
              </div>
            </header>

            <div class="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
              <.form
                for={@form}
                id="reset_password_form"
                phx-submit="send_email"
                phx-change="validate"
              >
                <div class="space-y-6">
                  <fieldset class="fieldset mb-4">
                    <.input
                      field={@form[:email]}
                      type="email"
                      label="Email"
                      placeholder="you@example.com"
                      required
                      class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                    />
                  </fieldset>

                  <button
                    type="submit"
                    class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                    phx-disable-with="Sending..."
                  >
                    Send reset instructions
                  </button>
                </div>
              </.form>

              <div class="mt-6 text-center">
                <p class="text-sm text-base-content/70">
                  Remember your password?
                  <.link
                    navigate={~p"/users/log-in"}
                    class="font-semibold text-blue-600 hover:underline"
                  >
                    Sign in
                  </.link>
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{}, as: :user)
    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    form = to_form(user_params, as: :user)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      # In a real app, you'd generate a token and send an email
      # For now, we'll just show a success message
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset-password/#{&1}")
      )
    end

    # Always show success message regardless of whether email exists
    # to prevent email enumeration attacks
    info = "If your email is in our system, you will receive password reset instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/users/log-in")}
  end
end
