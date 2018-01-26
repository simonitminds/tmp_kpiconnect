defmodule Oceanconnect.Accounts.Auth do

  # TODO: consider getting rid of this module and moving this into Auth Plug
  def current_user(conn) do
    OceanconnectWeb.Plugs.Auth.current_user(conn)
  end
end
