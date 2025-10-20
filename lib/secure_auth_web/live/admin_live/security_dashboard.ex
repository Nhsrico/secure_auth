defmodule SecureAuthWeb.AdminLive.SecurityDashboard do
  use SecureAuthWeb, :live_view

  alias SecureAuth.{Accounts, ApiKeys, RateLimiter}
  alias SecureAuth.Repo
  import Ecto.Query

  def render(assigns) do


    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>

<%= if @show_create_user_form do %>
  <div class="fixed inset-0 bg-black/40 flex items-center justify-center">
    <div class="bg-white rounded-xl shadow p-6 w-full max-w-lg">
      <h3 class="text-lg font-semibold mb-4">Create User</h3>

      <!-- Error summary (shown when the changeset is invalid) -->
      <%= if @new_user_changeset && @new_user_changeset.action == :insert && @new_user_changeset.errors != [] do %>
        <div class="mb-3 text-sm text-red-700 bg-red-50 border border-red-200 rounded p-3">
          <p class="font-medium mb-1">Please fix the errors and try again:</p>
          <ul class="list-disc ml-5">
            <%= for {field, {msg, _}} <- @new_user_changeset.errors do %>
              <li><%= Phoenix.Naming.humanize(field) %>: <%= msg %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <!-- Plain HTML form -->
      <form id="create-user-form" phx-submit="create_user" class="space-y-3">
        <label class="block text-sm">Email
          <input name="user[email]" type="email" required
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <label class="block text-sm">Name
          <input name="user[name]" type="text"
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <label class="block text-sm">Phone (required)
          <input name="user[phone_number]" type="text" required
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <label class="block text-sm">Password (required)
          <input name="user[password]" type="password" required
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <p class="text-xs text-gray-500 mt-2">Provide <strong>either</strong> SSN <em>or</em> Passport Number</p>
        <label class="block text-sm">SSN (optional if Passport provided)
          <input name="user[ssn]" type="text"
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <label class="block text-sm">Passport Number (optional if SSN provided)
          <input name="user[passport_number]" type="text"
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <label class="block text-sm">Next of Kin Passport Number (required)
          <input name="user[next_of_kin_passport]" type="text" required
                 class="mt-1 w-full px-3 py-2 rounded border" />
        </label>

        <div class="pt-2 flex gap-2">
          <button type="submit" class="px-4 py-2 rounded bg-blue-600 text-white">Create</button>
          <button type="button" phx-click="cancel_create_user" class="px-4 py-2 rounded border">
            Cancel
          </button>
        </div>
      </form>
    </div>
  </div>
<% end %>


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
                <p class="text-3xl font-bold text-gray-900"><%= @total_users %></p>
              </div>
              <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-users" class="w-6 h-6 text-blue-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                <%= @verified_users %> verified accounts
              </span>
            </div>
          </div>

    <!-- 2FA Enabled -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">2FA Enabled</p>
                <p class="text-3xl font-bold text-green-600"><%= @two_fa_users %></p>
              </div>
              <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-shield-check" class="w-6 h-6 text-green-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                <%= @two_fa_percentage %>% adoption rate
              </span>
            </div>
          </div>

    <!-- API Keys Active -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Active API Keys</p>
                <p class="text-3xl font-bold text-purple-600"><%= @active_api_keys %></p>
              </div>
              <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-key" class="w-6 h-6 text-purple-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                <%= @api_requests_today %> requests today
              </span>
            </div>
          </div>

    <!-- Rate Limited IPs -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Rate Limited IPs</p>
                <p class="text-3xl font-bold text-red-600"><%= @rate_limited_count %></p>
              </div>
              <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-red-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                <%= @login_attempts_24h %> login attempts today
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
                        phx-debounce="300"
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
                              <p class="font-medium text-gray-900"><%= user.email%></p>
                              <p class="text-sm text-gray-500"><%= user.name%></p>
                              <p class="text-xs text-gray-400">ID: <%=user.id%></p>
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
                                  <%= human_status(user.verification_status) %>
                                </span>
                              </div>
                              <p class="text-xs text-gray-500 mt-1">
                                Joined <%= Calendar.strftime(user.inserted_at, "%b %d, %Y")%>
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
                          <p class="text-sm text-gray-900"><%= activity.description%></p>
                          <p class="text-xs text-gray-500"><%= activity.timestamp%></p>
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
                    <p class="text-xs text-gray-400">Last 30 days: <%= @registrations_30d%> new users</p>
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
                      <span class="font-medium"><%= @successful_logins_24h%></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Failed attempts (24h)</span>
                      <span class="font-medium text-red-600"><%= @failed_logins_24h%></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">2FA verifications (24h)</span>
                      <span class="font-medium text-green-600"><%= @totp_verifications_24h%></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Magic link uses (24h)</span>
                      <span class="font-medium text-blue-600"><%= @magic_link_uses_24h%></span>
                    </div>
                  </div>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">API Usage</h3>
                  <div class="space-y-4">
                    <div class="flex justify-between">
                      <span class="text-gray-600">Total API requests (24h)</span>
                      <span class="font-medium"><%= @api_requests_24h%></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Unique API keys used</span>
                      <span class="font-medium"><%= @unique_api_keys_24h%></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Rate limited requests</span>
                      <span class="font-medium text-red-600"><%= @rate_limited_requests_24h%></span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-600">Average response time</span>
                      <span class="font-medium"><%= @avg_response_time%>ms</span>
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
                    Connections: <%=@db_connections%> / <%=@db_pool_size%>
                  </p>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-600">Memory Usage</p>
                      <p class="text-2xl font-bold text-blue-600"><%=@memory_usage%>%</p>
                    </div>
                    <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                      <.icon name="hero-cpu-chip" class="w-6 h-6 text-blue-600" />
                    </div>
                  </div>
                  <p class="text-xs text-gray-500 mt-2">
                    <%=@memory_used%>MB / <%=@memory_total%>MB
                  </p>
                </div>

                <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-600">Uptime</p>
                      <p class="text-2xl font-bold text-purple-600"><%=@system_uptime%></p>
                    </div>
                    <div class="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                      <.icon name="hero-clock" class="w-6 h-6 text-purple-600" />
                    </div>
                  </div>
                  <p class="text-xs text-gray-500 mt-2">
                    Since <%=@last_restart%>
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

  defp human_status(nil), do: "Pending"
  defp human_status(status) when is_binary(status), do: String.capitalize(status)

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket) do
    if authorized?(user) do
      # start a periodic refresh after the LV connects to the client
      if connected?(socket) do
        :timer.send_interval(5_000, :refresh_security)  # every 5s
      end

      {:ok,
       socket
       |> assign(:active_tab, "users")
       |> assign(:user_filter, "all")
       |> assign(:search_form, to_form(%{}, as: "search"))
      # NEW: defaults so render won't crash
     |> assign(:show_create_user_form, false)
     |> assign(:new_user_changeset, Accounts.change_user_registration(%Accounts.User{}))

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
  {:noreply, search_users(socket, to_string(query))}
end

@impl true
def handle_event("search_users", params, socket) do
  q =
    params
    |> get_in(["search", "query"])
    |> to_string()
    |> String.trim()

  {:noreply, search_users(socket, q)}
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
         |> put_flash(:info, "User #{user.email}> has been verified.")
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
         |> put_flash(:info, "User #{user.email}> has been suspended.")
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
         |> put_flash(:info, "User #{user.email}> has been activated.")
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
           |> put_flash(:info, "User #{user.email}> has been permanently deleted.")
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

# Clear ALL rate limits (tries RateLimiter.dump/0 else ETS)
def handle_event("clear_all_rate_limits", _params, socket) do
  cleared =
    cond do
      Code.ensure_loaded?(RateLimiter) and function_exported?(RateLimiter, :dump, 0) ->
        for {ip, %{action: act}} <- RateLimiter.dump() do
          RateLimiter.reset_rate_limit(ip, act)
        end
        |> length()

      :ets.whereis(:rate_limiter_requests) != :undefined ->
        sz = :ets.info(:rate_limiter_requests, :size) || 0
        :ets.delete_all_objects(:rate_limiter_requests)
        sz

      true ->
        0
    end

  {:noreply,
   socket
   |> put_flash(:info, "Cleared #{cleared} rate-limit entr#{if cleared == 1, do: "y", else: "ies"}.")
   |> load_rate_limits()}
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

# Export a simple CSV report (users summary)
def handle_event("export_security_report", _params, socket) do
  import Ecto.Query
  alias Phoenix.LiveView
  rows =
    from(u in SecureAuth.Accounts.User,
      select: {u.email, u.verification_status, u.two_factor_enabled, u.inserted_at}
    )
    |> SecureAuth.Repo.all()

  csv =
    [["email","status","2fa","joined"] |
     Enum.map(rows, fn {e,s,t,dt} -> [e, s, (t && "true") || "false", Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")] end)]
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")

  {:noreply,
   LiveView.send_download(socket, {:binary, csv}, filename: "security_report.csv", content_type: "text/csv")}
end

# Cleanup expired API keys (deactivate)
def handle_event("cleanup_expired_tokens", _params, socket) do
  import Ecto.Query
  alias SecureAuth.ApiKeys.ApiKey

  now = DateTime.utc_now() |> DateTime.truncate(:second)

  {count, _} =
    from(k in ApiKey, where: not is_nil(k.expires_at) and k.expires_at <= ^now and k.is_active == true)
    |> SecureAuth.Repo.update_all(set: [is_active: false])

  {:noreply,
   socket
   |> put_flash(:info, "Deactivated #{count} expired API key#{if count == 1, do: "", else: "s"}.")
   |> load_metrics()}
end


# Send a digest email to admins (uses Swoosh Local/Test in dev/test)
def handle_event("send_security_digest", _params, socket) do
  import Ecto.Query
  alias SecureAuth.{Repo, Accounts.User, Mailer}
  alias Swoosh.Email

  alerts = socket.assigns[:security_alerts] || []
  body =
    alerts
    |> Enum.map(fn a -> "- [#{a.severity}] #{a.title}: #{a.description}" end)
    |> Enum.join("\n")

  admin_emails =
    from(u in User, where: u.is_admin == true, select: u.email)
    |> Repo.all()

  Enum.each(admin_emails, fn to ->
    Email.new()
    |> Email.to(to)
    |> Email.from({"Security", "no-reply@secureauth.local"})
    |> Email.subject("Security digest")
    |> Email.text_body(if body == "", do: "No alerts.", else: body)
    |> Mailer.deliver()
  end)

  {:noreply, put_flash(socket, :info, "Security digest sent to #{length(admin_emails)} admin(s).")}
end


@impl true
def handle_event("show_create_user_form", _params, socket) do
  {:noreply, assign(socket, show_create_user_form: true)}
end

@impl true
def handle_event("cancel_create_user", _params, socket) do
  {:noreply, assign(socket, show_create_user_form: false)}
end

@impl true
def handle_event("create_user", %{"user" => params}, socket) do
  case Accounts.register_user(params) do
    {:ok, _user} ->
      {:noreply,
       socket
       |> put_flash(:info, "User created.")
       |> assign(show_create_user_form: false)
       |> load_users()}

    {:error, changeset} ->
      {:noreply, assign(socket,
        new_user_changeset: changeset,
        show_create_user_form: true
      )}
  end
end


#Add a catch-all so unknown events don’t explode:
@impl true
def handle_event(event, _params, socket) do
  require Logger
  Logger.warning("Unhandled event: #{inspect(event)}")
  {:noreply, socket}
end


  @impl true
  def handle_info(:refresh_security, socket) do
    {:noreply,
    socket
    |> load_rate_limits()
    |> load_system_health()}
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

defp search_users(socket, ""), do: load_users(socket)

defp search_users(socket, query) do
  import Ecto.Query

  # escape LIKE wildcards and force lowercase for case-insensitive match
  q =
    query
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[%_]/, "\\\\\\0")   # escape % and _
  pattern = "%#{q}%"

  users =
    from(u in Accounts.User,
      where:
        like(fragment("lower(?)", u.email), ^pattern) or
        like(fragment("lower(coalesce(?, ''))", u.name), ^pattern),
      order_by: [desc: u.inserted_at]
    )
    |> Repo.all()

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
    if total_users > 0, do: Float.round(two_fa_users / total_users * 100, 1), else: 0.0

  socket
  |> assign(:total_users, total_users)
  |> assign(:verified_users, verified_users)
  |> assign(:two_fa_users, two_fa_users)
  |> assign(:two_fa_percentage, two_fa_percentage)
  # real (or safe) values instead of placeholders:
  |> assign(:active_api_keys, count_active_api_keys())
  |> assign(:api_requests_today, count_api_requests_today())
  |> assign(:rate_limited_count, count_rate_limited())
  |> assign(:login_attempts_24h, count_login_attempts_24h())
end



  # Normalize one rate-limit entry into neat strings
defp present_rate_limit({ip, data}) when is_map(data) do
  %{
    ip: ip_to_string(ip),
    action: Map.get(data, :action) || Map.get(data, "action") || "unknown",
    remaining_time:
      remaining(Map.get(data, :window_ends_at) || Map.get(data, "window_ends_at"))
  }
end

# Convert an IP tuple or binary to "x.x.x.x"
defp ip_to_string({_,_,_,_} = ip4), do: ip4 |> :inet.ntoa() |> to_string()
defp ip_to_string({_,_,_,_,_,_,_,_} = ip6), do: ip6 |> :inet.ntoa() |> to_string()
defp ip_to_string(ip) when is_binary(ip), do: ip
defp ip_to_string(other), do: to_string(other)

# Pretty remaining time from a DateTime/NaiveDateTime
defp remaining(nil), do: "—"
defp remaining(%NaiveDateTime{} = ends),
  do: remaining(DateTime.from_naive!(ends, "Etc/UTC"))
defp remaining(%DateTime{} = ends) do
  diff = DateTime.diff(ends, DateTime.utc_now(), :second)
  cond do
    diff <= 0 -> "expired"
    true ->
      "#{div(diff, 60)}m #{rem(diff, 60)}s"
  end
end
defp remaining(other), do: to_string(other)


defp load_rate_limits(socket) do
  items =
    cond do
      Code.ensure_loaded?(RateLimiter) and function_exported?(RateLimiter, :dump, 0) ->
        # Prefer your RateLimiter.dump/0 if you have it
        RateLimiter.dump()

      # Fallback to ETS if your limiter uses it
      :ets.whereis(:rate_limiter_requests) != :undefined ->
        :ets.tab2list(:rate_limiter_requests)

      true ->
        []
    end

  view_rows =
    Enum.map(items, fn
      # common shape: {ip, %{action: ..., window_ends_at: ..., count: ...}}
      {ip, data} when is_map(data) ->
        %{
          ip: ip_to_string(ip),
          action: Map.get(data, :action) || Map.get(data, "action") || "unknown",
          remaining_time:
            remaining_str(Map.get(data, :window_ends_at) || Map.get(data, "window_ends_at"))
        }

      # unknown shape: show something readable but never crash
      other ->
        %{ip: "n/a", action: "unknown", remaining_time: to_string(other)}
    end)

  assign(socket, :rate_limits, view_rows)
end



defp remaining_str(nil), do: "—"
defp remaining_str(%NaiveDateTime{} = ndt),
  do: ndt |> DateTime.from_naive!("Etc/UTC") |> remaining_str()
defp remaining_str(%DateTime{} = ends) do
  diff = DateTime.diff(ends, DateTime.utc_now(), :second)
  if diff <= 0, do: "expired", else: "#{div(diff, 60)}m #{rem(diff, 60)}s"
end
defp remaining_str(other), do: to_string(other)


defp remaining_str(dt) do
  diff = DateTime.diff(dt, DateTime.utc_now(), :second)
  if diff <= 0, do: "expired", else: "#{div(diff, 60)}m #{rem(diff, 60)}s"
end



defp load_security_alerts(socket) do
  alerts =
    []
    |> maybe_alert_failed_logins()
    |> maybe_alert_rate_limited_ips()
    |> maybe_alert_expiring_api_keys()
    |> maybe_alert_pending_users()

  assign(socket, :security_alerts, alerts)
end
# --- ALERT BUILDERS ---

# A) Burst of failed logins in the last 15 minutes, grouped by IP
defp maybe_alert_failed_logins(acc) do
  case failed_login_bursts() do
    [] -> acc
    bursts ->
      # one alert per noisy IP
      burst_alerts =
        Enum.map(bursts, fn %{ip: ip, count: count, last_at: last_at} ->
          %{
            id: "failed_logins:#{ip}:#{DateTime.to_unix(last_at)}",
            title: "Multiple failed login attempts",
            description: "IP #{ip} made #{count} failed attempts in the last 15 minutes",
            severity: if(count >= 10, do: "high", else: "medium"),
            timestamp: fmt_ts(last_at)
          }
        end)

      acc ++ burst_alerts
  end
end

# B) Currently rate-limited IPs from RateLimiter / ETS
defp maybe_alert_rate_limited_ips(acc) do
  items =
    cond do
      Code.ensure_loaded?(RateLimiter) and function_exported?(RateLimiter, :dump, 0) ->
        RateLimiter.dump()
      :ets.whereis(:rate_limiter_requests) != :undefined ->
        :ets.tab2list(:rate_limiter_requests)
      true -> []
    end

  case items do
    [] -> acc
    list ->
      count = length(list)
      now = DateTime.utc_now()
      [
        %{
          id: "rate_limited:#{DateTime.to_unix(now)}",
          title: "Active rate limits",
          description: "#{count} IP#{if count == 1, do: "", else: "s"} currently rate-limited",
          severity: if(count >= 5, do: "medium", else: "low"),
          timestamp: fmt_ts(now)
        }
      ] ++ acc
  end
end

# C) API keys expiring soon or deactivated
defp maybe_alert_expiring_api_keys(acc) do
  if Code.ensure_loaded?(SecureAuth.ApiKeys.ApiKey) do
    import Ecto.Query
    alias SecureAuth.ApiKeys.ApiKey

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    soon = DateTime.add(now, 7 * 24 * 3600, :second) # next 7 days

    expiring =
      from(k in ApiKey,
        where: not is_nil(k.expires_at) and k.expires_at <= ^soon and k.is_active == true,
        select: %{id: k.id, name: k.name, expires_at: k.expires_at}
      )
      |> Repo.all()

    deactivated =
      from(k in ApiKey,
        where: k.is_active == false,
        select: %{id: k.id, name: k.name, updated_at: k.updated_at}
      )
      |> Repo.all()

    expiring_alerts =
      Enum.map(expiring, fn k ->
        %{
          id: "key_expiring:#{k.id}",
          title: "API key expiring soon",
          description: "#{k.name || "Key #{k.id}"} expires #{relative_time(k.expires_at)}",
          severity: "medium",
          timestamp: fmt_ts(k.expires_at)
        }
      end)

    deactivated_alerts =
      Enum.map(deactivated, fn k ->
        %{
          id: "key_deactivated:#{k.id}",
          title: "API key deactivated",
          description: "#{k.name || "Key #{k.id}"} is inactive",
          severity: "low",
          timestamp: fmt_ts(k.updated_at || now)
        }
      end)

    acc ++ expiring_alerts ++ deactivated_alerts
  else
    acc
  end
end

# D) Many users pending verification
defp maybe_alert_pending_users(acc) do
  import Ecto.Query
  pending =
    Repo.aggregate(
      from(u in Accounts.User, where: u.verification_status == "pending"),
      :count, :id
    )

  if pending > 0 do
    now = DateTime.utc_now()
    acc ++ [
      %{
        id: "pending_users:#{DateTime.to_unix(now)}",
        title: "Pending verifications",
        description: "#{pending} user#{if pending == 1, do: "", else: "s"} awaiting verification",
        severity: if(pending >= 20, do: "medium", else: "low"),
        timestamp: fmt_ts(now)
      }
    ]
  else
    acc
  end
end

# --- DATA SOURCES ---

# Try a LoginAttempt schema if you have one; otherwise return []
defp failed_login_bursts do
  now = DateTime.utc_now() |> DateTime.truncate(:second)
  window_start = DateTime.add(now, -15 * 60, :second)

  # If you have SecureAuth.Security.LoginAttempt schema (adjust module name/fields if different):
  if Code.ensure_loaded?(SecureAuth.Security.LoginAttempt) do
    import Ecto.Query
    alias SecureAuth.Security.LoginAttempt

    # expect fields: :success (boolean), :ip (string or tuple), :inserted_at
    rows =
      from(a in LoginAttempt,
        where: (a.success == false or is_nil(a.success)) and a.inserted_at >= ^window_start,
        select: %{ip: a.ip, inserted_at: a.inserted_at}
      )
      |> Repo.all()

    rows
    |> Enum.group_by(fn r -> ip_to_string(r.ip) end)
    |> Enum.map(fn {ip, list} ->
      %{
        ip: ip,
        count: length(list),
        last_at: Enum.max_by(list, & &1.inserted_at).inserted_at
      }
    end)
    |> Enum.filter(&(&1.count >= 5)) # threshold: 5 fails in 15 min
  else
    []
  end
end


defp fmt_ts(nil), do: "—"
defp fmt_ts(%DateTime{}=dt), do: Calendar.strftime(dt, "%b %d, %Y %H:%M UTC")
defp fmt_ts(%NaiveDateTime{}=ndt),
  do: ndt |> DateTime.from_naive!("Etc/UTC") |> fmt_ts()
defp fmt_ts(other), do: to_string(other)

defp relative_time(%DateTime{}=dt),
  do: human_diff(DateTime.diff(dt, DateTime.utc_now(), :second))
defp relative_time(%NaiveDateTime{}=ndt),
  do: ndt |> DateTime.from_naive!("Etc/UTC") |> relative_time()
defp relative_time(_), do: "soon"

defp human_diff(sec) when is_integer(sec) do
  cond do
    sec <= 0 -> "now"
    sec < 3600 -> "#{div(sec,60)}m"
    sec < 86_400 -> "#{div(sec,3600)}h"
    true -> "#{div(sec,86_400)}d"
  end
end


defp load_analytics(socket) do
  socket
  # Keep or replace registrations_30d with a real query when you have it
  |> assign(:registrations_30d, Repo.aggregate(Accounts.User, :count, :id))
  # The rest now call helpers (easy to swap to real queries later)
  |> assign(:successful_logins_24h, 0)         # wire to your real source if available
  |> assign(:failed_logins_24h, 0)             # wire to your real source if available
  |> assign(:totp_verifications_24h, 0)        # wire to your real source if available
  |> assign(:magic_link_uses_24h, 0)           # wire to your real source if available
  |> assign(:api_requests_24h, count_api_requests_24h())
  |> assign(:unique_api_keys_24h, count_unique_api_keys_24h())
  |> assign(:rate_limited_requests_24h, count_rate_limited_requests_24h())
  |> assign(:avg_response_time, avg_response_time_ms())
end


defp load_system_health(socket) do
  # BEAM memory (bytes) -> MB
  total_bytes = :erlang.memory(:total)
  used_mb = div(total_bytes, 1024 * 1024)

  # If you know your machine's total RAM, set in config :secure_auth, :total_system_mem_mb
  total_mb = Application.get_env(:secure_auth, :total_system_mem_mb)
  percent =
    case total_mb do
      n when is_integer(n) and n > 0 -> Float.round(used_mb / n * 100, 1)
      _ -> 0.0
    end

  proc_count = length(Process.list())
  run_queue = :erlang.statistics(:run_queue)

  started_at = socket.assigns[:_lv_started_at] || DateTime.utc_now()
  uptime_sec = DateTime.diff(DateTime.utc_now(), started_at, :second)

  socket
  |> assign(:_lv_started_at, started_at)
  |> assign(:memory_used, used_mb)
  |> assign(:memory_total, total_mb || used_mb)
  |> assign(:memory_usage, percent)
  |> assign(:db_connections, db_connections_guess())
  |> assign(:db_pool_size, Repo.config()[:pool_size] || 10)
  |> assign(:system_uptime, format_duration(uptime_sec))
  |> assign(:last_restart, Calendar.strftime(started_at, "%b %d, %Y %H:%M:%S UTC"))
  |> assign(:process_count, proc_count)
  |> assign(:run_queue, run_queue)
end


defp format_duration(s) when is_integer(s) do
  d = div(s, 86_400)
  h = rem(div(s, 3_600), 24)
  m = rem(div(s, 60), 60)
  cond do
    d > 0 -> "#{d}d #{h}h #{m}m"
    h > 0 -> "#{h}h #{m}m"
    true  -> "#{m}m"
  end
end

# For SQLite, “active DB connections” isn’t very meaningful; give a reasonable number
defp db_connections_guess do
  # If you later use Postgres, swap this for a real SQL count against pg_stat_activity.
  Repo.config()[:pool_size] || 1
end


defp load_recent_activities(socket) do
  activities =
    (recent_user_signups() ++ recent_logins() ++ recent_api_keys() ++ recent_2fa_enables())
    |> Enum.sort_by(& &1.timestamp_dt, {:desc, DateTime})
    |> Enum.take(20)
    |> Enum.map(fn a -> Map.delete(a, :timestamp_dt) end) # keep only display fields

  assign(socket, :recent_activities, activities)
end

# --- RECENT ACTIVITY SOURCES ---

defp recent_user_signups do
  import Ecto.Query
  SecureAuth.Accounts.User
  |> order_by([u], desc: u.inserted_at)
  |> limit(10)
  |> Repo.all()
  |> Enum.map(fn u ->
    ts = to_dt(u.inserted_at)
    %{
      type: "user_verified", # or "user_signup" if you prefer
      description: "User #{u.email} registered",
      timestamp: fmt_ts(ts),
      timestamp_dt: ts
    }
  end)
end

defp recent_logins do
  import Ecto.Query
  # Pull from users_tokens (session tokens) for authenticated sessions in last 24h
  since = DateTime.utc_now() |> DateTime.add(-24 * 3600, :second) |> DateTime.truncate(:second)

  from(t in "users_tokens",
    where: t.context == "session" and not is_nil(t.authenticated_at) and t.authenticated_at >= ^since,
    join: u in SecureAuth.Accounts.User, on: u.id == t.user_id,
    order_by: [desc: t.authenticated_at],
    select: %{email: u.email, at: t.authenticated_at}
  )
  |> Repo.all()
  |> Enum.map(fn %{email: email, at: at} ->
    ts = to_dt(at)
    %{
      type: "login_success",
      description: "Successful login for #{email}",
      timestamp: fmt_ts(ts),
      timestamp_dt: ts
    }
  end)
end

defp recent_api_keys do
  import Ecto.Query
  if Code.ensure_loaded?(SecureAuth.ApiKeys.ApiKey) do
    SecureAuth.ApiKeys.ApiKey
    |> order_by([k], desc: k.inserted_at)
    |> limit(10)
    |> Repo.all()
    |> Enum.map(fn k ->
      ts = to_dt(k.inserted_at)
      label = k.name || "Key #{k.id}"
      %{
        type: "api_key_created",
        description: "API key created: #{label}",
        timestamp: fmt_ts(ts),
        timestamp_dt: ts
      }
    end)
  else
    []
  end
end

defp recent_2fa_enables do
  import Ecto.Query
  # Heuristic: users with two_factor_enabled=true, ordered by updated_at
  from(u in SecureAuth.Accounts.User,
    where: u.two_factor_enabled == true,
    order_by: [desc: u.updated_at],
    limit: 10,
    select: %{email: u.email, at: u.updated_at}
  )
  |> Repo.all()
  |> Enum.map(fn %{email: email, at: at} ->
    ts = to_dt(at)
    %{
      type: "2fa_enabled",
      description: "2FA enabled for #{email}",
      timestamp: fmt_ts(ts),
      timestamp_dt: ts
    }
  end)
end

# --- formatting helpers ---

defp to_dt(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")
defp to_dt(%DateTime{} = dt), do: dt
defp to_dt(_), do: DateTime.utc_now()

defp fmt_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y %H:%M UTC")


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


  # ---------- SAFE COUNTERS (no crashes, return real numbers when available) ----------

# Active API keys (prefers ApiKeys context; falls back to counting a schema if present; else 0)
# Count active API keys without assuming column names
defp count_active_api_keys do
  import Ecto.Query
  now = DateTime.utc_now() |> DateTime.truncate(:second)

  Repo.aggregate(
    from(k in SecureAuth.ApiKeys.ApiKey,
      where: k.is_active == true and (is_nil(k.expires_at) or k.expires_at > ^now)
    ),
    :count,
    :id
  )
end

# Rate-limited IPs (prefers RateLimiter.dump/0; else ETS size; else 0)
defp count_rate_limited do
  cond do
    Code.ensure_loaded?(RateLimiter) and function_exported?(RateLimiter, :dump, 0) ->
      RateLimiter.dump() |> length()

    :ets.whereis(:rate_limiter_requests) != :undefined ->
      :ets.info(:rate_limiter_requests, :size) || 0

    true ->
      0
  end
end

# Login attempts in last 24h (adjust schema/module if you have one; else 0)
defp count_login_attempts_24h do
  # If you have a Security.LoginAttempt schema (or similar), uncomment & adapt:
  # import Ecto.Query
  # from(a in SecureAuth.Security.LoginAttempt,
  #   where: a.inserted_at >= from_now(-24, "hour")
  # )
  # |> Repo.aggregate(:count, :id)

  0
end

# Total API requests today (needs a request log or metrics table; else 0)
defp count_api_requests_today do
  # If you keep a request_logs table, implement similar to the login attempts example
  0
end

# API usage last 24h (placeholders now wired to helpers so it's easy to swap later)
defp count_api_requests_24h, do: 0
defp count_unique_api_keys_24h, do: 0
defp count_rate_limited_requests_24h, do: 0
defp avg_response_time_ms, do: 0



end
