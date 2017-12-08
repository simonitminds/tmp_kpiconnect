ExUnit.start()
Application.ensure_all_started(:hound)
Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, :manual)
