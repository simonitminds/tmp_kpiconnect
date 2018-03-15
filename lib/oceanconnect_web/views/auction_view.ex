defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view

  def auction_without_associations_from_changeset(struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:port)
    |> Map.delete(:vessel)
    |> Map.delete(:fuel)
    |> Map.delete(:buyer)
    |> Map.delete(:suppliers)
  end

  def errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def auction_status(auction) do
    %{status: status} = Oceanconnect.Auctions.get_auction_state(auction)
    status
  end
end
