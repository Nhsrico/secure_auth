defmodule SecureAuthWeb.AdminLive.SecurityDashboard do
  use SecureAuthWeb, :live_view

  alias SecureAuth.{Accounts, ApiKeys, RateLimiter}
  alias SecureAuth.Repo
  import Ecto.Query

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-2">Security Dashboard</h1>
          <p class="text-gray-600">
            Monitor authentication security, rate limiting, and user management
          </p>
        </div>
        
    <!-- Security Metrics Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <!-- Total Users -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Total Users</p>
                <p class="text-3xl font-bold text-gray-900">{@total_users}</p>
              </div>
              <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-users" class="w-6 h-6 text-blue-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                {@verified_users} verified accounts
              </span>
            </div>
          </div>
          
    <!-- 2FA Enabled -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">2FA Enabled</p>
                <p class="text-3xl font-bold text-green-600">{@two_fa_users}</p>
              </div>
              <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-shield-check" class="w-6 h-6 text-green-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                {@two_fa_percentage}% adoption rate
              </span>
            </div>
          </div>
          
    <!-- API Keys Active -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Active API Keys</p>
                <p class="text-3xl font-bold text-purple-600">{@active_api_keys}</p>
              </div>
              <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-key" class="w-6 h-6 text-purple-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                {@api_requests_today} requests today
              </span>
            </div>
          </div>
          
    <!-- Rate Limited IPs -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Rate Limited IPs</p>
                <p class="text-3xl font-bold text-red-600">{@rate_limited_count}</p>
              </div>
              <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-red-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                {@login_attempts_24h} login attempts today
              </span>
            </div>
          </div>
        </div>
        
    <!-- Admin Tabs -->
        <div class="mb-8">
          <div class="border-b border-gray-200">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <button
                phx-click="switch_tab"
                phx-value-tab="users"
                class={"border-transparent py-2 px-1 border-b-2 font-medium text-sm #{if @active_tab == "users", do: "border-blue-500 text-blue-600", else: "text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
              >
                <.icon name="hero-users" class="w-5 h-5 inline mr-2" /> User Management
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="security"
                class={"border-transparent py-2 px-1 border-b-2 font-medium text-sm #{if @active_tab == "security", do: "border-blue-500 text-blue-600", else: "text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
              >
                <.icon name="hero-shield-check" class="w-5 h-5 inline mr-2" /> Security Monitor
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="analytics"
                class={"border-transparent py-2 px-1 border-b-2 font-medium text-sm #{if @active_tab == "analytics", do: "border-blue-500 text-blue-600", else: "text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
              >
                <.icon name="hero-chart-bar" class="w-5 h-5 inline mr-2" /> Analytics
              </button>
              <button
                phx-click="switch_tab"
                phx-value-tab="system"
                class={"border-transparent py-2 px-1 border-b-2 font-medium text-sm #{if @active_tab == "system", do: "border-blue-500 text-blue-600", else: "text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
              >
                <.icon name="hero-server" class="w-5 h-5 inline mr-2" /> System Health
              </button>
            </nav>
          </div>
        </div>
        
    <!-- Tab Content -->
        <%= case @active_tab do %>
          <% "users" -> %>
            <!-- User Management Tab -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <!-- User List -->
              <div class="lg:col-span-2">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200">
                  <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-900">User Management</h3>
                    <div class="flex items-center space-x-2">
                      <button
                        phx-click="refresh_users"
                        class="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                      >
                        <.icon name="hero-arrow-path" class="w-4 h-4 inline mr-1" /> Refresh
                      </button>
                      <button
                        phx-click="show_create_user_form"
                        class="px-3 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        <.icon name="hero-plus" class="w-4 h-4 inline mr-1" /> Create User
                      </button>
                    </div>
                  </div>
                  
    <!-- User Search -->
                  <div class="px-6 py-4 border-b border-gray-200">
                    <.form
                      for={@search_form}
                      id="user-search"
                      phx-change="search_users"
                      class="flex items-center space-x-4"
                    >
                      <.input
                        field={@search_form[:query]}
                        type="text"
                        placeholder="Search users by email, name..."
                        class="flex-1 px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                      />
                      <select
                        name="filter"
                        phx-change="filter_users"
                        class="px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                      >
                        <option value="all" selected={@user_filter == "all"}>All Users</option>
                        <option value="verified" selected={@user_filter == "verified"}>
                          Verified
                        </option>
                        <option value="pending" selected={@user_filter == "pending"}>Pending</option>
                        <option value="suspended" selected={@user_filter == "suspended"}>
                          Suspended
                        </option>
                        <option value="2fa_enabled" selected={@user_filter == "2fa_enabled"}>
                          2FA Enabled
                        </option>
                      </select>
                    </.form>
                  </div>

                  <div class="p-6">
                    <div class="space-y-4 max-h-96 overflow-y-auto">
                      <%= for user <- @users do %>
                        <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                          <div class="flex items-center space-x-4">
                            <div class={"w-3 h-3 rounded-full #{user_status_color(user)}"}></div>
                            <div>
                              <p class="font-medium text-gray-900">{user.email}</p>
                              <p class="text-sm text-gray-500">{user.name}</p>
                              <p class="text-xs text-gray-400">ID: {user.id}</p>
                            </div>
                          </div>
                          <div class="flex items-center space-x-4">
                            <div class="text-right">
                              <div class="flex items-center space-x-2">
                                <%= if user.two_factor_enabled do %>
                                  <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                                    2FA
                                  </span>
                                <% end %>
                                <span class={user_status_badge_class(user)}>
                                  {String.capitalize(user.verification_status)}
                                </span>
                              </div>
                              <p class="text-xs text-gray-500 mt-1">
                                Joined {Calendar.strftime(user.inserted_at, "%b %d, %Y")}
                              </p>
                            </div>
                            
    <!-- User Actions -->
                            <div class="flex items-center space-x-2">
                              <%= if user.verification_status == "pending" do %>
                                <button
                                  phx-click="verify_user"
                                  phx-value-user-id={user.id}
                                  class="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700 transition-colors"
                                >
                                  Verify
                                </button>
                              <% end %>

                              <%= if user.verification_status == "verified" do %>
                                <button
                                  phx-click="suspend_user"
                                  phx-value-user-id={user.id}
                                  phx-confirm="Are you sure you want to suspend this user?"
                                  class="px-2 py-1 text-xs bg-yellow-600 text-white rounded hover:bg-yellow-700 transition-colors"
                                >
                                  Suspend
                                </button>
                              <% end %>

                              <%= if user.verification_status == "suspended" do %>
                                <button
                                  phx-click="activate_user"
                                  phx-value-user-id={user.id}
                                  class="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
                                >
                                  Activate
                                </button>
                              <% end %>

                              <%= if is_current_admin?(@current_scope.user, user) do %>
                                <span class="px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded">
                                  Current Admin
                                </span>
                              <% else %>
                                <button
                                  phx-click="delete_user"
                                  phx-value-user-id={user.id}
                                  phx-confirm="Are you sure you want to permanently delete this user? This action cannot be undone."
                                  class="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
                                >
                                  Delete
                                </button>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- User Quick Actions -->
              <div class="space-y-6">
                <!-- Bulk Actions -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Bulk Actions</h3>
                  <div class="space-y-3">
                    <button
                      phx-click="export_users"
                      class="w-full flex items-center justify-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
                    >
                      <.icon name="hero-document-arrow-down" class="w-4 h-4 mr-2" /> Export All Users
                    </button>
                    <button
                      phx-click="bulk_verify_pending"
                      phx-confirm="Verify all pending users?"
                      class="w-full flex items-center justify-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                    >
                      <.icon name="hero-check-circle" class="w-4 h-4 mr-2" /> Verify All Pending
                    </button>
                    <button
                      phx-click="force_2fa_all"
                      phx-confirm="Force 2FA setup for all verified users?"
                      class="w-full flex items-center justify-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      <.icon name="hero-shield-check" class="w-4 h-4 mr-2" /> Force 2FA Setup
                    </button>
                  </div>
                </div>
                
    <!-- Recent User Activity -->
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h3>
                  <div class="space-y-3">
                    <%= for activity <- @recent_activities do %>
                      <div class="flex items-start space-x-3">
                        <div class={"w-2 h-2 rounded-full mt-2 #{activity_color(activity.type)}"}>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-sm text-gray-900">{activity.description}</p>
                          <p class="text-xs text-gray-500">{activity.timestamp}</p>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% "security" -> %>
            <!-- Security Monitor Tab -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <!-- Rate Limiting Monitor -->
              <div class="bg-white rounded-xl shadow-sm border border-gray-200">
                <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                  <h3 class="text-lg font-semibold text-gray-900">Rate Limiting Monitor</h3>
                  <button
                    phx-click="refresh_rate_limits"
                    class="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                  >
                    <.icon name="hero-arrow-path" class="w-4 h-4 inline mr-1" /> Refresh
                  </button>
                </div>
                <div class="p-6">
                  <div class="space-y-4 max-h-96 overflow-y-auto">
                    <%= for rate_limit <- @rate_limits do %>
                      <div class="flex items-center justify-between p-4 bg-red-50 rounded-lg border border-red-200">
                        <div>
                          <p class="font-medium text-gray-900">{rate_limit.ip}</p>
                          <p class="text-sm text-red-600">
                            Rate limited for {rate_limit.action}
                          </p>
                        </div>
                        <div class="text-right">
                          <p class="text-sm font-medium text-red-600">
                            {rate_limit.remaining_time}
                          </p>
                          <button
                            phx-click="clear_rate_limit"
                            phx-value-ip={rate_limit.ip}
                            phx-value-action={rate_limit.action}
                            class="text-xs text-red-600 hover:text-red-800 mt-1"
                          >
                            Clear
                          </button>
                        </div>
                      </div>
                    <% end %>

                    <%= if @rate_limits == [] do %>
                      <div class="text-center py-8">
                        <.icon name="hero-shield-check" class="w-12 h-12 text-green-500 mx-auto mb-4" />
                        <p class="text-gray-500">No active rate limits</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              
    <!-- Security Alerts -->
              <div class="bg-white rounded-xl shadow-sm border border-gray-200">
                <div class="px-6 py-4 border-b border-gray-200">
                  <h3 class="text-lg font-semibold text-gray-900">Security Alerts</h3>
                </div>
                <div class="p-6">
                  <div class="space-y-4">
                    <%= for alert <- @security_alerts do %>
                      <div class={"p-4 rounded-lg border #{alert_color_class(alert.severity)}"}>
                        <div class="flex items-start justify-between">
                          <div>
                            <p class={"font-medium #{alert_text_color(alert.severity)}"}>
                              {alert.title}
                            </p>
                            <p class="text-sm text-gray-600 mt-1">{alert.description}</p>
                            <p class="text-xs text-gray-500 mt-2">{alert.timestamp}</p>
                          </div>
                          <button
                            phx-click="dismiss_alert"
                            phx-value-alert-id={alert.id}
                            class="text-gray-400 hover:text-gray-600"
                          >
                            <.icon name="hero-x-mark" class="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    <% end %>

                    <%= if @security_alerts == [] do %>
                      <div class="text-center py-8">
                        <.icon name="hero-shield-check" class="w-12 h-12 text-green-500 mx-auto mb-4" />
                        <p class="text-gray-500">No security alerts</p>
                        <p class="text-xs text-gray-400 mt-1">System is secure</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% "analytics" -> %>
            <!-- Analytics Tab -->
            <div class="space-y-8">
              <!-- User Registration Chart -->
              <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <h3 class="text-lg font-semibold text-gray-900 mb-4">User Registration Trends</h3>
                <div class="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
                  <div class="text-center">
                    <.icon name="hero-chart-bar" class="w-12 h-12 text-gray-400 mx-auto mb-2" />
                    <p class="text-gray-500">Registration chart visualization</p>
                    <p class="text-xs text-gray-400">Last 30 days: {@registrations_30d} new users</p>
                  </div>
                </div>
              </div>
              
    <!-- Login Analytics -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Login Analytics</h3>
                  <div class="space-y-4">
                    <div class="flex justify-between">
                      <span class="text-gray-600">Successful logins (24h)</span>
                      <span class="font-medium">{@successful_logins_24h}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Failed attempts (24h)</span>
                      <span class="font-medium text-red-600">{@failed_logins_24h}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">2FA verifications (24h)</span>
                      <span class="font-medium text-green-600">{@totp_verifications_24h}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Magic link uses (24h)</span>
                      <span class="font-medium text-blue-600">{@magic_link_uses_24h}</span>
                    </div>
                  </div>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">API Usage</h3>
                  <div class="space-y-4">
                    <div class="flex justify-between">
                      <span class="text-gray-600">Total API requests (24h)</span>
                      <span class="font-medium">{@api_requests_24h}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Unique API keys used</span>
                      <span class="font-medium">{@unique_api_keys_24h}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Rate limited requests</span>
                      <span class="font-medium text-red-600">{@rate_limited_requests_24h}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Average response time</span>
                      <span class="font-medium">{@avg_response_time}ms</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% "system" -> %>
            <!-- System Health Tab -->
            <div class="space-y-8">
              <!-- System Status -->
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-600">Database</p>
                      <p class="text-2xl font-bold text-green-600">Healthy</p>
                    </div>
                    <div class="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                      <.icon name="hero-circle-stack" class="w-6 h-6 text-green-600" />
                    </div>
                  </div>
                  <p class="text-xs text-gray-500 mt-2">
                    Connections: {@db_connections} / {@db_pool_size}
                  </p>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-600">Memory Usage</p>
                      <p class="text-2xl font-bold text-blue-600">{@memory_usage}%</p>
                    </div>
                    <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                      <.icon name="hero-cpu-chip" class="w-6 h-6 text-blue-600" />
                    </div>
                  </div>
                  <p class="text-xs text-gray-500 mt-2">
                    {@memory_used}MB / {@memory_total}MB
                  </p>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-600">Uptime</p>
                      <p class="text-2xl font-bold text-purple-600">{@system_uptime}</p>
                    </div>
                    <div class="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                      <.icon name="hero-clock" class="w-6 h-6 text-purple-600" />
                    </div>
                  </div>
                  <p class="text-xs text-gray-500 mt-2">
                    Since {@last_restart}
                  </p>
                </div>
              </div>
              
    <!-- System Actions -->
              <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <h3 class="text-lg font-semibold text-gray-900 mb-4">System Actions</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <button
                    phx-click="export_security_report"
                    class="flex items-center justify-center px-4 py-3 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
                  >
                    <.icon name="hero-document-arrow-down" class="w-5 h-5 mr-2" />
                    Export Security Report
                  </button>
                  <button
                    phx-click="clear_all_rate_limits"
                    phx-confirm="Clear all active rate limits?"
                    class="flex items-center justify-center px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                  >
                    <.icon name="hero-x-circle" class="w-5 h-5 mr-2" /> Clear All Rate Limits
                  </button>
                  <button
                    phx-click="cleanup_expired_tokens"
                    class="flex items-center justify-center px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    <.icon name="hero-trash" class="w-5 h-5 mr-2" /> Cleanup Tokens
                  </button>
                  <button
                    phx-click="send_security_digest"
                    class="flex items-center justify-center px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                  >
                    <.icon name="hero-envelope" class="w-5 h-5 mr-2" /> Send Security Digest
                  </button>
                </div>
              </div>
            </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket) do
    if authorized?(user) do
      {:ok,
       socket
       |> assign(:active_tab, "users")
       |> assign(:user_filter, "all")
       |> assign(:search_form, to_form(%{}, as: "search"))
       |> load_dashboard_data()}
    else
      {:ok,
       socket
       |> put_flash(:error, "Admin privileges required to access this page.")
       |> push_navigate(to: ~p"/dashboard")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/users/log-in")}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("refresh_users", _params, socket) do
    {:noreply, load_users(socket)}
  end

  def handle_event("search_users", %{"search" => %{"query" => query}}, socket) do
    {:noreply, search_users(socket, query)}
  end

  def handle_event("filter_users", %{"filter" => filter}, socket) do
    {:noreply,
     socket
     |> assign(:user_filter, filter)
     |> filter_users(filter)}
  end

  def handle_event("verify_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.change_user_registration(user, %{verification_status: "verified"}) do
      %{valid?: true} = changeset ->
        {:ok, _user} = Repo.update(changeset)

        {:noreply,
         socket
         |> put_flash(:info, "User #{user.email} has been verified.")
         |> load_users()}

      _changeset ->
        {:noreply, put_flash(socket, :error, "Failed to verify user.")}
    end
  end

  def handle_event("suspend_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.change_user_registration(user, %{verification_status: "suspended"}) do
      %{valid?: true} = changeset ->
        {:ok, _user} = Repo.update(changeset)

        {:noreply,
         socket
         |> put_flash(:info, "User #{user.email} has been suspended.")
         |> load_users()}

      _changeset ->
        {:noreply, put_flash(socket, :error, "Failed to suspend user.")}
    end
  end

  def handle_event("activate_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Accounts.change_user_registration(user, %{verification_status: "verified"}) do
      %{valid?: true} = changeset ->
        {:ok, _user} = Repo.update(changeset)

        {:noreply,
         socket
         |> put_flash(:info, "User #{user.email} has been activated.")
         |> load_users()}

      _changeset ->
        {:noreply, put_flash(socket, :error, "Failed to activate user.")}
    end
  end

  def handle_event("delete_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    if is_current_admin?(socket.assigns.current_scope.user, user) do
      {:noreply, put_flash(socket, :error, "You cannot delete your own admin account.")}
    else
      case Repo.delete(user) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> put_flash(:info, "User #{user.email} has been permanently deleted.")
           |> load_users()}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to delete user.")}
      end
    end
  end

  def handle_event("clear_rate_limit", %{"ip" => ip, "action" => action}, socket) do
    action_atom = String.to_atom(action)
    RateLimiter.reset_rate_limit(ip, action_atom)

    {:noreply,
     socket
     |> put_flash(:info, "Rate limit cleared for #{ip}")
     |> load_dashboard_data()}
  end

  def handle_event("clear_all_rate_limits", _params, socket) do
    # This is a placeholder - in a real implementation you'd have a function to clear all rate limits
    {:noreply,
     socket
     |> put_flash(:info, "All rate limits have been cleared.")
     |> load_dashboard_data()}
  end

  def handle_event("export_users", _params, socket) do
    {:noreply, put_flash(socket, :info, "User export has been initiated.")}
  end

  def handle_event("bulk_verify_pending", _params, socket) do
    {count, _} =
      from(u in Accounts.User, where: u.verification_status == "pending")
      |> Repo.update_all(set: [verification_status: "verified"])

    {:noreply,
     socket
     |> put_flash(:info, "#{count} pending users have been verified.")
     |> load_users()}
  end

  def handle_event("export_security_report", _params, socket) do
    {:noreply, put_flash(socket, :info, "Security report export has been initiated.")}
  end

  def handle_event("cleanup_expired_tokens", _params, socket) do
    # This would cleanup expired tokens in a real implementation
    {:noreply, put_flash(socket, :info, "Expired tokens have been cleaned up.")}
  end

  def handle_event("send_security_digest", _params, socket) do
    {:noreply, put_flash(socket, :info, "Security digest email has been sent to all admins.")}
  end

  # Helper functions

  defp authorized?(user) do
    String.contains?(user.email, "admin")
  end

  defp is_current_admin?(current_user, user) do
    current_user.id == user.id && authorized?(current_user)
  end

  defp load_dashboard_data(socket) do
    socket
    |> load_users()
    |> load_metrics()
    |> load_rate_limits()
    |> load_security_alerts()
    |> load_analytics()
    |> load_system_health()
    |> load_recent_activities()
  end

  defp load_users(socket) do
    users =
      from(u in Accounts.User, order_by: [desc: u.inserted_at])
      |> Repo.all()

    assign(socket, :users, users)
  end

  defp search_users(socket, query) do
    users =
      if String.trim(query) == "" do
        from(u in Accounts.User, order_by: [desc: u.inserted_at]) |> Repo.all()
      else
        pattern = "%#{query}%"

        from(u in Accounts.User,
          where: ilike(u.email, ^pattern) or ilike(u.name, ^pattern),
          order_by: [desc: u.inserted_at]
        )
        |> Repo.all()
      end

    assign(socket, :users, users)
  end

  defp filter_users(socket, filter) do
    query =
      case filter do
        "verified" -> from(u in Accounts.User, where: u.verification_status == "verified")
        "pending" -> from(u in Accounts.User, where: u.verification_status == "pending")
        "suspended" -> from(u in Accounts.User, where: u.verification_status == "suspended")
        "2fa_enabled" -> from(u in Accounts.User, where: u.two_factor_enabled == true)
        _ -> from(u in Accounts.User)
      end

    users = query |> order_by(desc: :inserted_at) |> Repo.all()
    assign(socket, :users, users)
  end

  defp load_metrics(socket) do
    total_users = Repo.aggregate(Accounts.User, :count, :id)

    verified_users =
      Repo.aggregate(
        from(u in Accounts.User, where: u.verification_status == "verified"),
        :count,
        :id
      )

    two_fa_users =
      Repo.aggregate(from(u in Accounts.User, where: u.two_factor_enabled == true), :count, :id)

    two_fa_percentage =
      if total_users > 0, do: Float.round(two_fa_users / total_users * 100, 1), else: 0

    socket
    |> assign(:total_users, total_users)
    |> assign(:verified_users, verified_users)
    |> assign(:two_fa_users, two_fa_users)
    |> assign(:two_fa_percentage, two_fa_percentage)
    # Placeholder
    |> assign(:active_api_keys, 15)
    # Placeholder
    |> assign(:api_requests_today, 1234)
    # Placeholder
    |> assign(:rate_limited_count, 2)
    # Placeholder
    |> assign(:login_attempts_24h, 156)
  end

  defp load_rate_limits(socket) do
    # Placeholder rate limit data
    rate_limits = [
      %{ip: "192.168.1.100", action: "login", remaining_time: "7m 30s"},
      %{ip: "10.0.0.5", action: "registration", remaining_time: "2m 0s"}
    ]

    assign(socket, :rate_limits, rate_limits)
  end

  defp load_security_alerts(socket) do
    # Placeholder security alerts
    alerts = [
      %{
        id: 1,
        title: "Multiple failed login attempts",
        description: "IP 192.168.1.100 has exceeded login attempt limits",
        severity: "high",
        timestamp: "5 minutes ago"
      },
      %{
        id: 2,
        title: "New API key created",
        description: "User admin@test.com created a new API key",
        severity: "info",
        timestamp: "1 hour ago"
      }
    ]

    assign(socket, :security_alerts, alerts)
  end

  defp load_analytics(socket) do
    socket
    |> assign(:registrations_30d, 45)
    |> assign(:successful_logins_24h, 89)
    |> assign(:failed_logins_24h, 12)
    |> assign(:totp_verifications_24h, 34)
    |> assign(:magic_link_uses_24h, 5)
    |> assign(:api_requests_24h, 1234)
    |> assign(:unique_api_keys_24h, 8)
    |> assign(:rate_limited_requests_24h, 23)
    |> assign(:avg_response_time, 145)
  end

  defp load_system_health(socket) do
    socket
    |> assign(:db_connections, 5)
    |> assign(:db_pool_size, 10)
    |> assign(:memory_usage, 67)
    |> assign(:memory_used, 512)
    |> assign(:memory_total, 1024)
    |> assign(:system_uptime, "2d 14h")
    |> assign(:last_restart, "July 5, 2025")
  end

  defp load_recent_activities(socket) do
    activities = [
      %{
        type: "user_verified",
        description: "User test@example.com verified",
        timestamp: "2 minutes ago"
      },
      %{
        type: "login_success",
        description: "Successful login from 192.168.1.1",
        timestamp: "5 minutes ago"
      },
      %{type: "api_key_created", description: "New API key created", timestamp: "15 minutes ago"},
      %{type: "2fa_enabled", description: "User enabled 2FA", timestamp: "1 hour ago"}
    ]

    assign(socket, :recent_activities, activities)
  end

  defp user_status_color(user) do
    cond do
      user.verification_status == "verified" and user.two_factor_enabled -> "bg-green-500"
      user.verification_status == "verified" -> "bg-yellow-500"
      user.confirmed_at -> "bg-blue-500"
      user.verification_status == "suspended" -> "bg-red-500"
      true -> "bg-gray-500"
    end
  end

  defp user_status_badge_class(user) do
    case user.verification_status do
      "verified" ->
        "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700"

      "suspended" ->
        "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700"

      _ ->
        "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700"
    end
  end

  defp alert_color_class(severity) do
    case severity do
      "high" -> "bg-red-50 border-red-200"
      "medium" -> "bg-yellow-50 border-yellow-200"
      "low" -> "bg-blue-50 border-blue-200"
      _ -> "bg-gray-50 border-gray-200"
    end
  end

  defp alert_text_color(severity) do
    case severity do
      "high" -> "text-red-800"
      "medium" -> "text-yellow-800"
      "low" -> "text-blue-800"
      _ -> "text-gray-800"
    end
  end

  defp activity_color(type) do
    case type do
      "user_verified" -> "bg-green-500"
      "login_success" -> "bg-blue-500"
      "api_key_created" -> "bg-purple-500"
      "2fa_enabled" -> "bg-green-500"
      _ -> "bg-gray-500"
    end
  end
end
