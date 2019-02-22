defmodule Oceanconnect.Auctions.AuctionComment do
  import Oceanconnect.Auctions.Guards

  @enforce_keys [:auction_id, :comment, :supplier_id]
  defstruct id: nil,
            auction_id: nil,
            supplier_id: nil,
            comment: nil,
            time_entered: DateTime.utc_now()

  def from_params_to_auction_comment(
    params = %{
      "comment" => comment,
      "supplier_id" => supplier_id,
      "time_entered" => time_entered
    },
    auction = %struct{}
  ) when is_auction(struct) do
    %__MODULE__{
      id: UUID.uuid4(:hex),
      auction_id: auction.id,
      supplier_id: supplier_id,
      comment: comment,
      time_entered: time_entered
    }
  end

  def from_event_comment(comment) do
    %__MODULE__{
      auction_id: nil,
      supplier_id: nil,
      comment: nil
    }
    |> Map.merge(comment)
  end
end
