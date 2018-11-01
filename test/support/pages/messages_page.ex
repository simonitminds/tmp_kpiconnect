defmodule Oceanconnect.MessagesPage do
  use Oceanconnect.Page

  def open_message_window do
    find_element(:css, ".qa-auction-messages")
    |> click()
  end

  def has_participating_auctions?(auctions) do
    Enum.all?(auctions, fn auction ->
      text = find_element(:css, ".qa-auction-messages-auctions")
      |> find_within_element(:css, ".qa-auction-messages-auction-#{auction.id}")
      |> inner_text

      Enum.any?(auction.vessels, &(text =~ &1.name))
    end)
  end
end
