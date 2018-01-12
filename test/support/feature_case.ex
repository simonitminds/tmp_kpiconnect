defmodule Oceanconnect.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      alias Oceanconnect.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      use Phoenix.ConnTest
      import OceanconnectWeb.Router.Helpers
      import Oceanconnect.Factory

      def login_user(session, user) do
        alias Oceanconnect.NewSessionPage
        NewSessionPage.visit(session)
        NewSessionPage.enter_credentials(session, user.email, user.password)
        NewSessionPage.submit(session)
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Oceanconnect.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Oceanconnect.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
