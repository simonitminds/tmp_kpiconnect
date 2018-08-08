defmodule OceanconnectWeb.Plugs.CheckAdmin do
	import Plug.Conn

	def init(default), do: default

	def call(conn, _) do
		current_user = Guardian.Plug.current_resource(conn)
		if current_user.is_admin do
			conn
		else
			conn
			|> put_status(404)
			|> Phoenix.Controller.put_flash(:warning, "Page not found")
			|> Phoenix.Controller.render(OceanconnectWeb.ErrorView, "404.html")
			|> halt()
		end
	end
end
