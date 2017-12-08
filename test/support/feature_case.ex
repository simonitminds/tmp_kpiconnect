defmodule Oceanconnect.Web.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Oceanconnect.Repo
      alias Oceanconnect.Page
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Oceanconnect.Factory
    end
  end

  setup tags do
    use Hound.Helpers
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Oceanconnect.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Oceanconnect.Repo, self())
    session = Hound.start_session()
    {:ok, session: session}
  end

end
