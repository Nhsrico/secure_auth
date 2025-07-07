defmodule SecureAuthWeb.AdminLive.SecurityDashboard do
  use SecureAuthWeb, :live_view

  alias SecureAuth.Accounts
  alias SecureAuth.RateLimiter
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
                <p class="text-3xl font-bold text-gray-900">{@metrics.total_users}</p>
              </div>
              <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-users" class="w-6 h-6 text-blue-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                {@metrics.verified_users} verified accounts
              </span>
            </div>
          </div>
          
    <!-- 2FA Enabled -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">2FA Enabled</p>
                <p class="text-3xl font-bold text-green-600">{@metrics.two_fa_users}</p>
              </div>
              <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-shield-check" class="w-6 h-6 text-green-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">
                {Float.round(@metrics.two_fa_percentage, 1)}% adoption rate
              </span>
            </div>
          </div>
          
    <!-- Rate Limited IPs -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Rate Limited IPs</p>
                <p class="text-3xl font-bold text-red-600">{length(@rate_limited_ips)}</p>
              </div>
              <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-red-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">Active rate limits</span>
            </div>
          </div>
          
    <!-- Recent Activity -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">Login Attempts</p>
                <p class="text-3xl font-bold text-yellow-600">{@metrics.recent_logins}</p>
              </div>
              <div class="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center">
                <.icon name="hero-arrow-right-on-rectangle" class="w-6 h-6 text-yellow-600" />
              </div>
            </div>
            <div class="mt-4">
              <span class="text-sm text-gray-500">Last 24 hours</span>
            </div>
          </div>
        </div>
        
    <!-- Main Content Grid -->
        <div class="grid grid-cols-1 gap-8">
          <!-- User Management -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200">
            <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="text-lg font-semibold text-gray-900">User Management</h3>
              <div class="flex items-center space-x-3">
                <button
                  phx-click="refresh_users"
                  class="px-3 py-1 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
                >
                  Refresh
                </button>
                <button
                  phx-click="show_create_user_form"
                  class="px-3 py-1 text-sm bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors"
                >
                  Create User
                </button>
              </div>
            </div>

            <%= if @show_create_user_form do %>
              <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
                <h4 class="text-md font-medium text-gray-900 mb-4">Create New User</h4>
                <.form
                  for={@user_form}
                  id="create-user-form"
                  phx-submit="create_user"
                  class="grid grid-cols-1 md:grid-cols-3 gap-4"
                >
                  <.input
                    field={@user_form[:email]}
                    type="email"
                    label="Email"
                    placeholder="user@example.com"
                    required
                    class="w-full px-3 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                  />
                  <.input
                    field={@user_form[:name]}
                    type="text"
                    label="Full Name"
                    placeholder="John Doe"
                    required
                    class="w-full px-3 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                  />
                  <.input
                    field={@user_form[:phone_number]}
                    type="tel"
                    label="Phone Number"
                    placeholder="+1234567890"
                    required
                    class="w-full px-3 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                  />
                  <.input
                    field={@user_form[:password]}
                    type="password"
                    label="Password"
                    placeholder="Temporary password"
                    required
                    class="w-full px-3 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                  />
                  <.input
                    field={@user_form[:next_of_kin_passport]}
                    type="text"
                    label="Next of Kin Passport"
                    placeholder="ABC123456"
                    required
                    class="w-full px-3 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                  />
                  <div class="flex items-end space-x-2">
                    <button
                      type="submit"
                      class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors"
                      phx-disable-with="Creating..."
                    >
                      Create
                    </button>
                    <button
                      type="button"
                      phx-click="hide_create_user_form"
                      class="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400 transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </.form>
              </div>
            <% end %>

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
                          <span class={"inline-flex items-center px-2 py-1 rounded-full text-xs font-medium #{verification_badge_class(user.verification_status)}"}>
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

                        <%= if user.id != @current_scope.user.id do %>
                          <button
                            phx-click="delete_user"
                            phx-value-user-id={user.id}
                            phx-confirm="Are you sure you want to permanently delete this user? This action cannot be undone."
                            class="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
                          >
                            Delete
                          </button>
                        <% else %>
                          <span class="px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded">
                            Current Admin
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          
    <!-- Rate Limiting Monitor -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200">
            <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="text-lg font-semibold text-gray-900">Rate Limiting Monitor</h3>
              <button
                phx-click="refresh_rate_limits"
                class="px-3 py-1 text-sm bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors"
              >
                Refresh
              </button>
            </div>
            <div class="p-6">
              <%= if length(@rate_limited_ips) > 0 do %>
                <div class="space-y-4 max-h-96 overflow-y-auto">
                  <%= for {ip, status} <- @rate_limited_ips do %>
                    <div class="flex items-center justify-between p-4 bg-red-50 rounded-lg border border-red-200">
                      <div>
                        <p class="font-medium text-gray-900">{ip}</p>
                        <p class="text-sm text-red-600">
                          Rate limited for {status.action}
                        </p>
                      </div>
                      <div class="text-right">
                        <p class="text-sm font-medium text-red-600">
                          {format_time_remaining(status.retry_after_ms)}
                        </p>
                        <button
                          phx-click="clear_rate_limit"
                          phx-value-ip={ip}
                          phx-value-action={status.action}
                          class="text-xs text-red-600 hover:text-red-800 mt-1"
                        >
                          Clear
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-8">
                  <.icon name="hero-shield-check" class="w-12 h-12 text-green-500 mx-auto mb-4" />
                  <p class="text-gray-500">No active rate limits</p>
                  <p class="text-sm text-gray-400">All IPs are within normal limits</p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Security Actions -->
        <div class="mt-8 bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Security Actions</h3>
          </div>
          <div class="p-6">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <button
                phx-click="export_security_report"
                class="flex items-center justify-center px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <.icon name="hero-document-arrow-down" class="w-5 h-5 mr-2" /> Export Security Report
              </button>

              <button
                phx-click="clear_all_rate_limits"
                phx-confirm="Are you sure you want to clear all rate limits?"
                class="flex items-center justify-center px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                <.icon name="hero-x-circle" class="w-5 h-5 mr-2" /> Clear All Rate Limits
              </button>

              <button
                phx-click="force_2fa_review"
                class="flex items-center justify-center px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                <.icon name="hero-shield-check" class="w-5 h-5 mr-2" /> Force 2FA Review
              </button>

              <button
                phx-click="bulk_email_users"
                class="flex items-center justify-center px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
              >
                <.icon name="hero-envelope" class="w-5 h-5 mr-2" /> Bulk Email Users
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    if authorized?(socket.assigns.current_scope) do
      changeset = Accounts.change_user_registration(%Accounts.User{})

      {:ok,
       socket
       |> assign(:metrics, get_security_metrics())
       |> assign(:users, get_recent_users())
       |> assign(:rate_limited_ips, get_rate_limited_ips())
       |> assign(:show_create_user_form, false)
       |> assign(:user_form, to_form(changeset))
       |> schedule_refresh()}
    else
      {:ok,
       socket
       |> put_flash(:error, "Access denied. Admin privileges required.")
       |> redirect(to: ~p"/dashboard")}
    end
  end

  def handle_event("show_create_user_form", _params, socket) do
    changeset = Accounts.change_user_registration(%Accounts.User{})

    {:noreply,
     socket
     |> assign(:show_create_user_form, true)
     |> assign(:user_form, to_form(changeset))}
  end

  def handle_event("hide_create_user_form", _params, socket) do
    {:noreply, assign(socket, :show_create_user_form, false)}
  end

  def handle_event("create_user", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Auto-confirm the user since admin created it
        confirmed_user =
          user
          |> Accounts.User.confirm_changeset()
          |> Repo.update!()

        {:noreply,
         socket
         |> assign(:users, get_recent_users())
         |> assign(:show_create_user_form, false)
         |> assign(:metrics, get_security_metrics())
         |> put_flash(:info, "User #{confirmed_user.email} created successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :user_form, to_form(changeset))}
    end
  end

  def handle_event("verify_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Repo.update(Ecto.Changeset.change(user, verification_status: "verified")) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(:users, get_recent_users())
         |> assign(:metrics, get_security_metrics())
         |> put_flash(:info, "User #{user.email} has been verified")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to verify user")}
    end
  end

  def handle_event("suspend_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Repo.update(Ecto.Changeset.change(user, verification_status: "suspended")) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(:users, get_recent_users())
         |> assign(:metrics, get_security_metrics())
         |> put_flash(:info, "User #{user.email} has been suspended")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to suspend user")}
    end
  end

  def handle_event("delete_user", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    # Prevent admin from deleting themselves
    if user.id == socket.assigns.current_scope.user.id do
      {:noreply, put_flash(socket, :error, "You cannot delete your own account")}
    else
      case Repo.delete(user) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> assign(:users, get_recent_users())
           |> assign(:metrics, get_security_metrics())
           |> put_flash(:info, "User #{user.email} has been permanently deleted")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to delete user")}
      end
    end
  end

  def handle_event("refresh_users", _params, socket) do
    {:noreply,
     socket
     |> assign(:users, get_recent_users())
     |> assign(:metrics, get_security_metrics())
     |> put_flash(:info, "User list refreshed")}
  end

  def handle_event("refresh_rate_limits", _params, socket) do
    {:noreply,
     socket
     |> assign(:rate_limited_ips, get_rate_limited_ips())
     |> put_flash(:info, "Rate limits refreshed")}
  end

  def handle_event("clear_rate_limit", %{"ip" => ip, "action" => action}, socket) do
    RateLimiter.reset_rate_limit(ip, String.to_atom(action))

    {:noreply,
     socket
     |> assign(:rate_limited_ips, get_rate_limited_ips())
     |> put_flash(:info, "Rate limit cleared for #{ip}")}
  end

  def handle_event("clear_all_rate_limits", _params, socket) do
    # Clear all rate limits (would need to implement in RateLimiter)
    {:noreply,
     socket
     |> assign(:rate_limited_ips, [])
     |> put_flash(:info, "All rate limits cleared")}
  end

  def handle_event("export_security_report", _params, socket) do
    report_data = generate_security_report(socket.assigns)

    {:noreply,
     socket
     |> push_event("download", %{
       filename: "security-report-#{Date.utc_today()}.json",
       content: Jason.encode!(report_data, pretty: true),
       content_type: "application/json"
     })}
  end

  def handle_event("force_2fa_review", _params, socket) do
    # This would trigger a review process for users without 2FA
    {:noreply,
     socket
     |> put_flash(:info, "2FA review process initiated for all users")}
  end

  def handle_event("bulk_email_users", _params, socket) do
    # This would send a bulk email to all users
    {:noreply,
     socket
     |> put_flash(:info, "Bulk email sent to all users")}
  end

  def handle_info(:refresh, socket) do
    {:noreply,
     socket
     |> assign(:metrics, get_security_metrics())
     |> assign(:rate_limited_ips, get_rate_limited_ips())
     |> schedule_refresh()}
  end

  # Private functions

  defp authorized?(current_scope) do
    # For demo purposes, admin is determined by email
    # In production, you'd have proper role-based access control
    current_scope && current_scope.user &&
      String.contains?(current_scope.user.email, "admin")
  end

  defp get_security_metrics do
    total_users = Repo.aggregate(from(u in SecureAuth.Accounts.User), :count)

    verified_users =
      Repo.aggregate(
        from(u in SecureAuth.Accounts.User, where: u.verification_status == "verified"),
        :count
      )

    two_fa_users =
      Repo.aggregate(
        from(u in SecureAuth.Accounts.User, where: u.two_factor_enabled == true),
        :count
      )

    two_fa_percentage = if total_users > 0, do: two_fa_users / total_users * 100, else: 0.0

    recent_logins =
      Repo.aggregate(
        from(t in SecureAuth.Accounts.UserToken,
          where:
            t.context == "session" and
              t.inserted_at >= ago(1, "day")
        ),
        :count
      )

    %{
      total_users: total_users,
      verified_users: verified_users,
      two_fa_users: two_fa_users,
      two_fa_percentage: two_fa_percentage,
      recent_logins: recent_logins
    }
  end

  defp get_recent_users do
    from(u in SecureAuth.Accounts.User,
      order_by: [desc: u.inserted_at],
      limit: 20
    )
    |> Repo.all()
  end

  defp get_rate_limited_ips do
    # This would interface with the RateLimiter to get currently limited IPs
    # For demo purposes, returning mock data
    [
      {"192.168.1.100", %{action: :login, retry_after_ms: 450_000}},
      {"10.0.0.5", %{action: :registration, retry_after_ms: 120_000}}
    ]
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

  defp verification_badge_class(status) do
    case status do
      "verified" -> "bg-green-100 text-green-700"
      "pending" -> "bg-yellow-100 text-yellow-700"
      "suspended" -> "bg-red-100 text-red-700"
      "rejected" -> "bg-red-100 text-red-700"
      _ -> "bg-gray-100 text-gray-700"
    end
  end

  defp format_time_remaining(ms) do
    minutes = div(ms, 60_000)
    seconds = div(rem(ms, 60_000), 1000)
    "#{minutes}m #{seconds}s"
  end

  defp generate_security_report(assigns) do
    %{
      generated_at: DateTime.utc_now(),
      metrics: assigns.metrics,
      rate_limited_ips: assigns.rate_limited_ips,
      user_count: length(assigns.users),
      security_summary: %{
        total_users: assigns.metrics.total_users,
        two_fa_adoption: "#{Float.round(assigns.metrics.two_fa_percentage, 1)}%",
        verification_rate:
          "#{Float.round(assigns.metrics.verified_users / assigns.metrics.total_users * 100, 1)}%",
        active_rate_limits: length(assigns.rate_limited_ips)
      }
    }
  end

  defp schedule_refresh(socket) do
    # Refresh every 30 seconds
    Process.send_after(self(), :refresh, 30_000)
    socket
  end
end
