defmodule Oceanconnect.MessagesPage do
  use Oceanconnect.Page
  alias Oceanconnect.Messages.Message

  def open_message_window do
    find_element(:css, ".qa-auction-messages")
    |> click()
  end

  def has_participating_auctions?(auctions) do
    Enum.all?(auctions, fn auction ->
      text = find_element(:css, ".qa-auction-messages-auctions")
      |> find_within_element(:css, ".qa-auction-#{auction.id}-message-payloads")
      |> inner_text

      Enum.any?(auction.vessels, &(text =~ &1.name))
    end)
  end

  def message_is_unread?(%Message{id: id}) do
    has_css?(".qa-message-id-#{id} [data-has-been-seen='true'")
  end
end
