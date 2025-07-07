defmodule SecureAuthWeb.PageController do
  use SecureAuthWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
