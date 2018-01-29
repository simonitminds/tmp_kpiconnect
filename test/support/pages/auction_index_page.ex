defmodule Oceanconnect.AuctionIndexPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/auctions")
  end

  def is_current_path? do
    current_path() == "/auctions"
  end

  def start_auction(auction) do
    find_element(:class, "qa-auction-#{auction.id}")
    |> find_within_element(:class, "qa-auction-start")
    |> click
  end

  def has_auctions?(auctions) do
    auctions
    |> Enum.all?(fn(auction) ->
      case search_element(:class, "qa-auction-#{auction.id}") do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  def auction_status(auction) do
    find_element(:class, "qa-auction-#{auction.id}")
    |> find_within_element(:class, "qa-auction-status")
    |> inner_text()
  end
end
