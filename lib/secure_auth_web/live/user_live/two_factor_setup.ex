defmodule SecureAuthWeb.UserLive.TwoFactorSetup do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts
  alias SecureAuth.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header class="text-center mb-8">
          Set Up Two-Factor Authentication
          <:subtitle>
            Secure your account with time-based one-time passwords (TOTP)
          </:subtitle>
        </.header>

        <div class="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
          <%= if @step == :setup do %>
            <!-- Step 1: Show QR Code and Secret -->
            <div class="text-center mb-6">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">
                Scan QR Code with Your Authenticator App
              </h3>
              
    <!-- Real QR Code -->
              <div class="bg-white p-4 rounded-lg border-2 border-gray-200 inline-block mb-4">
                <%= if @qr_code_svg do %>
                  <div class="qr-code-container">
                    {raw(@qr_code_svg)}
                  </div>
                <% else %>
                  <div class="w-48 h-48 bg-gray-100 border border-gray-300 rounded flex items-center justify-center">
                    <div class="text-center">
                      <div class="text-gray-500 mb-2">
                        <.icon name="hero-qr-code" class="w-12 h-12 mx-auto" />
                      </div>
                      <p class="text-sm text-gray-500">Generating QR Code...</p>
                    </div>
                  </div>
                <% end %>
              </div>
              
    <!-- Manual Entry Option -->
              <div class="mb-6">
                <p class="text-sm text-gray-600 mb-2">
                  Can't scan? Enter this code manually:
                </p>
                <div class="bg-gray-100 px-3 py-2 rounded text-sm font-mono break-all max-w-xs mx-auto">
                  {@totp_secret}
                </div>
              </div>
              
    <!-- Instructions -->
              <div class="text-left bg-blue-50 p-4 rounded-lg border border-blue-200 mb-6">
                <h4 class="font-medium text-blue-800 mb-2">Instructions:</h4>
                <ol class="text-sm text-blue-700 space-y-1 list-decimal list-inside">
                  <li>Install an authenticator app (Google Authenticator, Authy, etc.)</li>
                  <li>Scan the QR code or enter the secret manually</li>
                  <li>Enter the 6-digit code from your app below</li>
                </ol>
              </div>
            </div>
            
    <!-- Verification Form -->
            <.form for={@form} id="totp-verification-form" phx-submit="verify_totp" class="space-y-4">
              <.input
                field={@form[:totp_code]}
                type="text"
                label="Enter 6-digit code from your authenticator app"
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
                Verify and Enable 2FA
              </button>
            </.form>
          <% else %>
            <!-- Step 2: Success + Backup Codes -->
            <div class="text-center mb-6">
              <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <.icon name="hero-check" class="w-8 h-8 text-green-600" />
              </div>
              <h3 class="text-lg font-semibold text-gray-900 mb-2">
                Two-Factor Authentication Enabled!
              </h3>
              <p class="text-gray-600">
                Your account is now secured with 2FA. Save these backup codes in a safe place.
              </p>
            </div>
            
    <!-- Backup Codes -->
            <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
              <h4 class="font-medium text-yellow-800 mb-3">
                <.icon name="hero-exclamation-triangle" class="w-5 h-5 inline mr-2" />
                Backup Recovery Codes
              </h4>
              <p class="text-sm text-yellow-700 mb-3">
                Save these codes somewhere safe. You can use them to access your account if you lose your authenticator device.
              </p>
              <div class="grid grid-cols-2 gap-2 font-mono text-sm">
                <%= for code <- @backup_codes do %>
                  <div class="bg-white px-3 py-2 rounded border">
                    {code}
                  </div>
                <% end %>
              </div>
            </div>

            <div class="space-y-4">
              <button
                phx-click="download_codes"
                class="w-full bg-gray-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-gray-700 transition-colors"
              >
                Download Backup Codes
              </button>

              <.link
                navigate={~p"/users/settings"}
                class="block w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 text-center transition-colors"
              >
                Continue to Settings
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket) do
    if user.two_factor_enabled do
      {:ok, redirect(socket, to: ~p"/users/settings")}
    else
      # Generate new TOTP secret
      secret = NimbleTOTP.secret()
      qr_uri = NimbleTOTP.otpauth_uri("SecureAuth:#{user.email}", secret, issuer: "SecureAuth")

      # Generate QR code SVG
      qr_code_svg = generate_qr_code_svg(qr_uri)

      changeset = Accounts.change_user_registration(%User{})

      {:ok,
       socket
       |> assign(:step, :setup)
       |> assign(:totp_secret, Base.encode32(secret, padding: false))
       |> assign(:qr_uri, qr_uri)
       |> assign(:qr_code_svg, qr_code_svg)
       |> assign(:raw_secret, secret)
       |> assign(:backup_codes, [])
       |> assign_form(changeset)}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/users/log-in")}
  end

  def handle_event("verify_totp", %{"user" => %{"totp_code" => code}}, socket) do
    if NimbleTOTP.valid?(socket.assigns.raw_secret, code) do
      user = socket.assigns.current_scope.user
      backup_codes = generate_backup_codes()

      # Enable 2FA and save secret + backup codes
      case Accounts.enable_two_factor_auth(user, socket.assigns.raw_secret, backup_codes) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> assign(:step, :success)
           |> assign(:backup_codes, backup_codes)
           |> put_flash(:info, "Two-factor authentication has been enabled successfully!")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to enable two-factor authentication. Please try again.")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Invalid code. Please try again.")}
    end
  end

  def handle_event("download_codes", _params, socket) do
    codes_text = Enum.join(socket.assigns.backup_codes, "\n")

    {:noreply,
     socket
     |> push_event("download", %{
       filename: "secureauth-backup-codes.txt",
       content: codes_text,
       content_type: "text/plain"
     })}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end

  defp generate_backup_codes do
    for _ <- 1..8, do: :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end

  defp generate_qr_code_svg(qr_uri) do
    try do
      case QRCode.create(qr_uri) do
        {:ok, qr_code} ->
          matrix_to_svg(qr_code.matrix, 8)

        {:error, _reason} ->
          nil
      end
    rescue
      _ -> nil
    end
  end

  defp matrix_to_svg(matrix, scale) do
    size = length(matrix)
    svg_size = size * scale

    # Convert matrix to SVG rectangles
    rectangles =
      matrix
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, y} ->
        row
        |> Enum.with_index()
        |> Enum.filter(fn {cell, _x} -> cell == 1 end)
        |> Enum.map(fn {_cell, x} ->
          "<rect x=\"#{x * scale}\" y=\"#{y * scale}\" width=\"#{scale}\" height=\"#{scale}\" fill=\"black\"/>"
        end)
      end)
      |> Enum.join("")

    """
    <svg width="#{svg_size}" height="#{svg_size}" viewBox="0 0 #{svg_size} #{svg_size}" xmlns="http://www.w3.org/2000/svg">
      <rect width="#{svg_size}" height="#{svg_size}" fill="white"/>
      #{rectangles}
    </svg>
    """
  end
end
