defmodule SecureAuthWeb.UserLive.Dashboard do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <!-- Welcome Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-2">
            Welcome back, {@current_scope.user.name}!
          </h1>
          <p class="text-gray-600">
            Manage your secure account and settings from your dashboard.
          </p>
        </div>
        
    <!-- Account Status Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <!-- Account Status -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center mb-4">
              <div class="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-check-circle" class="w-6 h-6 text-green-600" />
              </div>
              <div class="ml-4">
                <h3 class="text-lg font-semibold text-gray-900">Account Status</h3>
                <p class="text-sm text-gray-600">Verified & Active</p>
              </div>
            </div>
            <div class="space-y-2">
              <div class="flex justify-between text-sm">
                <span class="text-gray-600">Email:</span>
                <span class="font-medium text-gray-900">{@current_scope.user.email}</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-gray-600">Member since:</span>
                <span class="font-medium text-gray-900">
                  {Calendar.strftime(@current_scope.user.inserted_at, "%B %Y")}
                </span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-gray-600">Verification:</span>
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                  {String.capitalize(@current_scope.user.verification_status)}
                </span>
              </div>
            </div>
          </div>
          
    <!-- Security Status -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center mb-4">
              <div class={"w-10 h-10 rounded-lg flex items-center justify-center #{if @current_scope.user.two_factor_enabled, do: "bg-blue-100", else: "bg-yellow-100"}"}>
                <.icon
                  name="hero-shield-check"
                  class={"w-6 h-6 #{if @current_scope.user.two_factor_enabled, do: "text-blue-600", else: "text-yellow-600"}"}
                />
              </div>
              <div class="ml-4">
                <h3 class="text-lg font-semibold text-gray-900">Security</h3>
                <p class="text-sm text-gray-600">
                  {if @current_scope.user.two_factor_enabled, do: "2FA Enabled", else: "2FA Disabled"}
                </p>
              </div>
            </div>
            <div class="space-y-2">
              <div class="flex justify-between text-sm">
                <span class="text-gray-600">Two-Factor Auth:</span>
                <span class={"inline-flex items-center px-2 py-1 rounded-full text-xs font-medium #{if @current_scope.user.two_factor_enabled, do: "bg-green-100 text-green-700", else: "bg-yellow-100 text-yellow-700"}"}>
                  {if @current_scope.user.two_factor_enabled, do: "Enabled", else: "Disabled"}
                </span>
              </div>
              <%= if @current_scope.user.two_factor_enabled do %>
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600">Last used:</span>
                  <span class="font-medium text-gray-900">
                    {if @current_scope.user.totp_last_used_at, do: "Recently", else: "Never"}
                  </span>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Quick Actions -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center mb-4">
              <div class="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-cog-6-tooth" class="w-6 h-6 text-purple-600" />
              </div>
              <div class="ml-4">
                <h3 class="text-lg font-semibold text-gray-900">Quick Actions</h3>
                <p class="text-sm text-gray-600">Manage your account</p>
              </div>
            </div>
            <div class="space-y-2">
              <.link
                navigate={~p"/users/settings"}
                class="block w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 rounded-md transition-colors"
              >
                Account Settings
              </.link>
              <%= if not @current_scope.user.two_factor_enabled do %>
                <.link
                  navigate={~p"/users/two-factor-setup"}
                  class="block w-full text-left px-3 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors"
                >
                  Enable 2FA Security
                </.link>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Recent Activity Section -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Recent Activity</h3>
          </div>
          <div class="p-6">
            <div class="space-y-4">
              <div class="flex items-center justify-between py-3 border-b border-gray-100 last:border-b-0">
                <div class="flex items-center">
                  <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                    <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4 text-green-600" />
                  </div>
                  <div class="ml-3">
                    <p class="text-sm font-medium text-gray-900">Successful login</p>
                    <p class="text-xs text-gray-500">
                      {if @current_scope.user.two_factor_enabled,
                        do: "with 2FA verification",
                        else: "via email/password"}
                    </p>
                  </div>
                </div>
                <span class="text-xs text-gray-500">Just now</span>
              </div>

              <%= if @current_scope.user.confirmed_at do %>
                <div class="flex items-center justify-between py-3 border-b border-gray-100 last:border-b-0">
                  <div class="flex items-center">
                    <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                      <.icon name="hero-envelope-open" class="w-4 h-4 text-blue-600" />
                    </div>
                    <div class="ml-3">
                      <p class="text-sm font-medium text-gray-900">Email confirmed</p>
                      <p class="text-xs text-gray-500">Account verification completed</p>
                    </div>
                  </div>
                  <span class="text-xs text-gray-500">
                    {Calendar.strftime(@current_scope.user.confirmed_at, "%b %d")}
                  </span>
                </div>
              <% end %>

              <%= if @current_scope.user.two_factor_enabled do %>
                <div class="flex items-center justify-between py-3 border-b border-gray-100 last:border-b-0">
                  <div class="flex items-center">
                    <div class="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                      <.icon name="hero-shield-check" class="w-4 h-4 text-purple-600" />
                    </div>
                    <div class="ml-3">
                      <p class="text-sm font-medium text-gray-900">
                        Two-factor authentication enabled
                      </p>
                      <p class="text-xs text-gray-500">Enhanced security activated</p>
                    </div>
                  </div>
                  <span class="text-xs text-gray-500">Recent</span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: _user}}} = socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/users/log-in")}
  end
end
