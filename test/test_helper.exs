Application.ensure_all_started(:hound)
ExUnit.start()

# TODO: Figure out why we have to do this and if its the right thing
 #Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, :manual)
 Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, {:shared, self()})




