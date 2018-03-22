defmodule OceanconnectWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest
      import Oceanconnect.Factory
      alias Oceanconnect.Utilities
      # The default endpoint for testing
      @endpoint OceanconnectWeb.Endpoint

      def build_conn() do
        %Plug.Conn{}
        |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
      end

      def assert_rounded_time_broadcast(auction, event, status, channel, expected_payload) do
        auction_id = auction.id
        receive do
          %Phoenix.Socket.Broadcast{
            event: ^event,
            payload: payload = %{time_remaining: _time, auction: %{id: ^auction_id}, state: %{status: ^status}}, topic: ^channel} ->
              assert Utilities.reduced_payload(payload) == Utilities.reduced_payload(expected_payload)
        after
          5000 ->
            assert false, "Expected message received nothing."
        end
      end
    end
  end


  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Oceanconnect.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, {:shared, self()})
    end
    :ok
  end

end
