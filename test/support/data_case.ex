defmodule Oceanconnect.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  import Oceanconnect.Auctions.Guards
  alias Oceanconnect.Auctions.AuctionSupervisor

  using do
    quote do
      alias Oceanconnect.Repo
      alias Oceanconnect.Utilities

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Oceanconnect.DataCase
      import Oceanconnect.Factory
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Oceanconnect.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Oceanconnect.Repo, {:shared, self()})
    end

    :ok
  end

  def all_values_match?(map, struct) do
    Enum.all?(map, fn {k, v} ->
      Map.fetch!(struct, k) == v
    end)
  end

  def start_auction_supervisor(auction = %struct{}, excluded_children \\ [])
      when is_auction(struct) do
    {:ok, pid} =
      start_supervised({AuctionSupervisor, {auction, %{exclude_children: excluded_children}}})

    on_exit(fn ->
      case DynamicSupervisor.which_children(Oceanconnect.Auctions.AuctionsSupervisor) do
        [] ->
          nil

        children ->
          Enum.map(children, fn {_, pid, _, _} ->
            Process.unlink(pid)
            Process.exit(pid, :shutdown)
          end)
      end
    end)

    {:ok, pid}
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
