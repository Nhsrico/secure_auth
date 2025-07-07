defmodule SecureAuthWeb.ApiKeysLive.Index do
  use SecureAuthWeb, :live_view

  alias SecureAuth.ApiKeys
  alias SecureAuth.ApiKeys.ApiKey

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-2">API Key Management</h1>
          <p class="text-gray-600">
            Generate and manage API keys for programmatic access to your account
          </p>
        </div>
        
    <!-- Create New Key Button -->
        <div class="mb-6">
          <button
            phx-click="show_create_form"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
          >
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> Create New API Key
          </button>
        </div>
        
    <!-- Create API Key Form -->
        <%= if @show_create_form do %>
          <div class="mb-8 bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Create New API Key</h3>

            <.form for={@form} id="api-key-form" phx-submit="create_api_key" class="space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  field={@form[:name]}
                  type="text"
                  label="Key Name"
                  placeholder="My API Key"
                  required
                  class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                />

                <.input
                  field={@form[:scope]}
                  type="select"
                  label="Permissions"
                  options={[{"Read Only", "read"}, {"Read & Write", "write"}, {"Admin", "admin"}]}
                  class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                />
              </div>

              <.input
                field={@form[:description]}
                type="textarea"
                label="Description (optional)"
                placeholder="Brief description of what this key will be used for"
                class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
              />

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <.input
                  field={@form[:expires_at]}
                  type="datetime-local"
                  label="Expiration Date (optional)"
                  class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                />

                <.input
                  field={@form[:rate_limit_per_minute]}
                  type="number"
                  label="Rate Limit (requests/minute)"
                  value="60"
                  min="1"
                  max="10000"
                  class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-gray-900 bg-white"
                />
              </div>

              <div class="flex items-center space-x-4">
                <button
                  type="submit"
                  class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
                  phx-disable-with="Creating..."
                >
                  Create API Key
                </button>
                <button
                  type="button"
                  phx-click="hide_create_form"
                  class="px-6 py-2 bg-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-400 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </.form>
          </div>
        <% end %>
        
    <!-- Success Message for New Key -->
        <%= if @newly_created_key do %>
          <div class="mb-8 bg-green-50 border border-green-200 rounded-xl p-6">
            <div class="flex items-start">
              <.icon name="hero-check-circle" class="w-6 h-6 text-green-600 mt-1 mr-3" />
              <div class="flex-1">
                <h3 class="text-lg font-semibold text-green-800 mb-2">
                  API Key Created Successfully!
                </h3>
                <p class="text-green-700 mb-4">
                  Your new API key has been generated. Please copy it now as it will not be shown again.
                </p>
                <div class="bg-white border border-green-300 rounded-lg p-4">
                  <div class="flex items-center justify-between">
                    <code class="text-sm font-mono text-gray-900 break-all">
                      {@newly_created_key.raw_key}
                    </code>
                    <button
                      phx-click="copy_key"
                      phx-value-key={@newly_created_key.raw_key}
                      class="ml-4 px-3 py-1 bg-green-600 text-white rounded text-sm hover:bg-green-700 transition-colors"
                    >
                      Copy
                    </button>
                  </div>
                </div>
                <button
                  phx-click="dismiss_new_key"
                  class="mt-4 text-sm text-green-600 hover:text-green-800"
                >
                  I've saved the key, dismiss this message
                </button>
              </div>
            </div>
          </div>
        <% end %>
        
    <!-- API Keys List -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Your API Keys</h3>
          </div>

          <%= if length(@api_keys) > 0 do %>
            <div class="divide-y divide-gray-200">
              <%= for api_key <- @api_keys do %>
                <div class="p-6">
                  <div class="flex items-center justify-between">
                    <div class="flex-1">
                      <div class="flex items-center space-x-4">
                        <h4 class="text-lg font-medium text-gray-900">{api_key.name}</h4>
                        <span class={"inline-flex items-center px-2 py-1 rounded-full text-xs font-medium #{scope_badge_class(api_key.scope)}"}>
                          {String.capitalize(api_key.scope)}
                        </span>
                        <%= if not api_key.is_active do %>
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
                            Revoked
                          </span>
                        <% end %>
                        <%= if ApiKey.expired?(api_key) do %>
                          <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
                            Expired
                          </span>
                        <% end %>
                      </div>

                      <div class="mt-2 text-sm text-gray-600">
                        <p><strong>Key ID:</strong> {api_key.key_prefix}••••••••</p>
                        <%= if api_key.description do %>
                          <p class="mt-1"><strong>Description:</strong> {api_key.description}</p>
                        <% end %>
                        <p class="mt-1">
                          <strong>Created:</strong> {Calendar.strftime(
                            api_key.inserted_at,
                            "%B %d, %Y at %I:%M %p"
                          )}
                        </p>
                        <%= if api_key.expires_at do %>
                          <p class="mt-1">
                            <strong>Expires:</strong> {Calendar.strftime(
                              api_key.expires_at,
                              "%B %d, %Y at %I:%M %p"
                            )}
                          </p>
                        <% end %>
                        <%= if api_key.last_used_at do %>
                          <p class="mt-1">
                            <strong>Last Used:</strong> {Calendar.strftime(
                              api_key.last_used_at,
                              "%B %d, %Y at %I:%M %p"
                            )}
                            <%= if api_key.last_used_ip do %>
                              from {api_key.last_used_ip}
                            <% end %>
                          </p>
                        <% else %>
                          <p class="mt-1 text-gray-500"><strong>Last Used:</strong> Never</p>
                        <% end %>
                        <p class="mt-1">
                          <strong>Total Requests:</strong> {api_key.request_count} |
                          <strong>Rate Limit:</strong> {api_key.rate_limit_per_minute}/min
                        </p>
                      </div>
                    </div>

                    <div class="flex items-center space-x-2">
                      <%= if api_key.is_active and not ApiKey.expired?(api_key) do %>
                        <button
                          phx-click="revoke_key"
                          phx-value-id={api_key.id}
                          phx-confirm="Are you sure you want to revoke this API key? This action cannot be undone."
                          class="px-3 py-1 bg-red-600 text-white rounded text-sm hover:bg-red-700 transition-colors"
                        >
                          Revoke
                        </button>
                      <% end %>
                      <button
                        phx-click="delete_key"
                        phx-value-id={api_key.id}
                        phx-confirm="Are you sure you want to permanently delete this API key? This action cannot be undone."
                        class="px-3 py-1 bg-gray-600 text-white rounded text-sm hover:bg-gray-700 transition-colors"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="p-8 text-center">
              <.icon name="hero-key" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">No API Keys</h3>
              <p class="text-gray-500 mb-4">You haven't created any API keys yet.</p>
              <button
                phx-click="show_create_form"
                class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
              >
                <.icon name="hero-plus" class="w-5 h-5 mr-2" /> Create Your First API Key
              </button>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok,
     socket
     |> assign(:api_keys, ApiKeys.list_api_keys(user))
     |> assign(:show_create_form, false)
     |> assign(:newly_created_key, nil)
     |> assign_form()}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/users/log-in")}
  end

  def handle_event("show_create_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_create_form, true)
     |> assign_form()}
  end

  def handle_event("hide_create_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_create_form, false)
     |> assign_form()}
  end

  def handle_event("create_api_key", %{"api_key" => api_key_params}, socket) do
    user = socket.assigns.current_scope.user

    case ApiKeys.create_api_key(user, api_key_params) do
      {:ok, api_key} ->
        {:noreply,
         socket
         |> assign(:api_keys, ApiKeys.list_api_keys(user))
         |> assign(:show_create_form, false)
         |> assign(:newly_created_key, api_key)
         |> put_flash(:info, "API key created successfully!")
         |> assign_form()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("revoke_key", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    try do
      api_key = ApiKeys.get_api_key!(user, id)

      case ApiKeys.revoke_api_key(api_key) do
        {:ok, _api_key} ->
          {:noreply,
           socket
           |> assign(:api_keys, ApiKeys.list_api_keys(user))
           |> put_flash(:info, "API key revoked successfully")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to revoke API key")}
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply, put_flash(socket, :error, "API key not found")}
    end
  end

  def handle_event("delete_key", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user

    try do
      api_key = ApiKeys.get_api_key!(user, id)

      case ApiKeys.delete_api_key(api_key) do
        {:ok, _api_key} ->
          {:noreply,
           socket
           |> assign(:api_keys, ApiKeys.list_api_keys(user))
           |> put_flash(:info, "API key deleted successfully")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to delete API key")}
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply, put_flash(socket, :error, "API key not found")}
    end
  end

  def handle_event("copy_key", %{"key" => key}, socket) do
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: key})
     |> put_flash(:info, "API key copied to clipboard!")}
  end

  def handle_event("dismiss_new_key", _params, socket) do
    {:noreply, assign(socket, :newly_created_key, nil)}
  end

  defp assign_form(socket, changeset \\ nil) do
    changeset = changeset || ApiKeys.change_new_api_key(socket.assigns.current_scope.user)
    assign(socket, form: to_form(changeset, as: "api_key"))
  end

  defp scope_badge_class(scope) do
    case scope do
      "read" -> "bg-blue-100 text-blue-700"
      "write" -> "bg-green-100 text-green-700"
      "admin" -> "bg-purple-100 text-purple-700"
      _ -> "bg-gray-100 text-gray-700"
    end
  end
end
