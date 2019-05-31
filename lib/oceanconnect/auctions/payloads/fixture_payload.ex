defmodule Oceanconnect.Auctions.Payloads.FixturePayload do
  import Oceanconnect.Auctions.Guards

  alias __MODULE__
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction
  }

  defstruct auction: nil,
            fixtures: []

  def get_fixture_payload!(auction = %Auction{}) do
    %FixturePayload{
      auction: auction,
      fixtures:
        Enum.map(Auctions.fixtures_for_auction(auction), fn %{price: price} = fixture ->
          %{fixture | price: Decimal.to_string(price)}
        end)
    }
  end
  def json_from_payload(%FixturePayload{
    auction: auction,
    fixtures: fixtures
      }) do
    %{
      auction: auction,
      fixtures: fixtures
    }
  end
end
