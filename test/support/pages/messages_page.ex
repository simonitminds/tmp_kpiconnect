defmodule Oceanconnect.MessagesPage do
  use Oceanconnect.Page
  alias Oceanconnect.Messages.Message

  def auction_conversation_unseen_count(auction_id, company_name) do
    :css
    |> find_element(".qa-auction-#{auction_id}-message-payloads")
    |> find_within_element(:css, ".qa-conversation-company-#{company_name}")
    |> find_within_element(:css, ".qa-messages-unseen-count")
    |> inner_text()
  end

  def has_participating_auctions?(auctions) do
    Enum.all?(auctions, fn auction ->
      text =
        find_element(:css, ".qa-auction-messages-auctions")
        |> find_within_element(:css, ".qa-auction-#{auction.id}-message-payloads")
        |> inner_text()

      Enum.any?(auction.vessels, &(text =~ &1.name))
    end)
  end

  def message_is_unseen?(%Message{id: id}) do
    has_css?(".qa-message-id-#{id}")
  end

  def open_auction_conversation(auction_id, company_name) do
    :css
    |> find_element(".qa-auction-#{auction_id}-message-payloads")
    |> find_within_element(:css, ".qa-conversation-company-#{company_name}")
    |> click()
  end

  def open_auction_message_payload(auction_id) do
    :css
    |> find_element(".qa-auction-#{auction_id}-message-payloads")
    |> click()
  end

  def open_message_window() do
    :css |> find_element(".qa-auction-messages") |> click()
  end
end
