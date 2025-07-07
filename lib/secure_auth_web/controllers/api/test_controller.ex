defmodule SecureAuthWeb.Api.TestController do
  use SecureAuthWeb, :controller

  def index(conn, _params) do
    user = conn.assigns[:current_user]
    api_key = conn.assigns[:current_api_key]

    response = %{
      message: "API access successful",
      user: %{
        id: user.id,
        email: user.email,
        name: user.name
      },
      api_key: %{
        id: api_key.id,
        name: api_key.name,
        scope: api_key.scope,
        last_used_at: api_key.last_used_at,
        request_count: api_key.request_count
      },
      timestamp: DateTime.utc_now()
    }

    json(conn, response)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]
    api_key = conn.assigns[:current_api_key]

    response = %{
      message: "API resource access successful",
      resource_id: id,
      user_email: user.email,
      api_key_scope: api_key.scope,
      timestamp: DateTime.utc_now()
    }

    json(conn, response)
  end
end
