defmodule Oceanconnect.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Oceanconnect.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      use Phoenix.ConnTest
      import OceanconnectWeb.Router.Helpers
      import Oceanconnect.Factory
      use Hound.Helpers
      import Oceanconnect.AsyncHelpers
      use Oceanconnect.Page

      def login_user(user) do
        alias Oceanconnect.NewSessionPage
        NewSessionPage.visit()
        NewSessionPage.enter_credentials(user.email, user.password)
        NewSessionPage.submit()
      end

      def convert_to_millisecs(time_remaining) do
        time = String.slice(time_remaining, 0..4)
        case String.split(time, ":") do
          [mins, secs] -> (String.to_integer(mins) * 60 + String.to_integer(secs)) * 1_000
          _ -> time_remaining
        end
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Oceanconnect.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Oceanconnect.Repo, self())
    Hound.start_session(metadata: metadata)

    {:ok, %{}}
  end
end
