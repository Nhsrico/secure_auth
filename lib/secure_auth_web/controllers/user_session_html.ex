defmodule SecureAuthWeb.UserSessionHTML do
  @moduledoc """
  This module contains pages rendered by UserSessionController.
  """
  use SecureAuthWeb, :html

  embed_templates "user_session_html/*"
end