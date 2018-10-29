defmodule Oceanconnect.AuctionMessagingPage do
  use Oceanconnect.Page

  def open_messaging_window do
    find_element(:css, ".qa-auction-messaging")
    |> click()
  end

  def has_participating_auctions?(auctions) do
    Enum.all?(auctions, fn auction ->
      text = find_element(:css, ".qa-auction-messaging-auctions")
      |> find_within_element(:css, ".qa-auction-messaging-auction-#{auction.id}")
      |> inner_text

      Enum.any?(auction.vessels, &(text =~ &1.name))
    end)
  end
end
