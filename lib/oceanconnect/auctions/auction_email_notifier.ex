defmodule Oceanconnect.Auctions.AuctionEmailNotifier do
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction}

  def notify_auction_created(auction = %Auction{}) do
    auction = auction |> Auctions.fully_loaded()
    invitation_emails = OceanconnectWeb.Email.auction_invitation(auction)
    invitation_emails = deliver_emails(invitation_emails)
    {:ok, invitation_emails}
  end

  def notify_upcoming_auction(auction = %Auction{}) do
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      OceanconnectWeb.Email.auction_starting_soon(auction)

    upcoming_emails = List.flatten([supplier_emails | buyer_emails])
    deliver_emails(upcoming_emails)
    {:ok, upcoming_emails}
  end

  def notify_auction_canceled(auction = %Auction{}) do
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      OceanconnectWeb.Email.auction_canceled(auction)

    cancellation_emails = List.flatten([supplier_emails | buyer_emails])
    deliver_emails(cancellation_emails)
    {:ok, cancellation_emails}
  end

  def notify_auction_completed(
        winning_solution_bids,
        submitted_barges,
        auction_id,
        active_participants
      ) do
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    approved_barges = Enum.filter(submitted_barges, &(&1.approval_status == "APPROVED"))

    emails =
      OceanconnectWeb.Email.auction_closed(
        winning_solution_bids,
        approved_barges,
        auction,
        active_participants
      )

    completion_emails =
      emails
      |> deliver_emails()

    {:ok, completion_emails}
  end

  defp deliver_emails(emails) do
    Enum.map(emails, fn email ->
      OceanconnectWeb.Mailer.deliver_later(email)
    end)
  end
end
