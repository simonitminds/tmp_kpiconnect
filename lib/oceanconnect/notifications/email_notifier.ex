defmodule Oceanconnect.Auctions.AuctionEmailNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions

  alias Oceanconnect.Notifications.Emails.{
    AuctionInvitation,
    AuctionRescheduled,
    AuctionStartingSoon,
    AuctionCanceled,
    AuctionClosed
  }

  def notify_auction_created(auction = %struct{}) when is_auction(struct) do
    auction = auction |> Auctions.fully_loaded()
    invitation_emails = OceanconnectWeb.Email.auction_invitation(auction)
    invitation_emails = deliver_emails(invitation_emails)
    {:ok, invitation_emails}
  end

  def notify_auction_rescheduled(auction = %struct{}) when is_auction(struct) do
    auction = auction |> Auctions.fully_loaded()
    updated_emails = OceanconnectWeb.Email.auction_rescheduled(auction)
    updated_emails = deliver_emails(updated_emails)
    {:ok, updated_emails}
  end

  def notify_upcoming_auction(auction = %struct{}) when is_auction(struct) do
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      OceanconnectWeb.Email.auction_starting_soon(auction)

    upcoming_emails = List.flatten([supplier_emails | buyer_emails])
    deliver_emails(upcoming_emails)
    {:ok, upcoming_emails}
  end

  def notify_auction_canceled(auction = %struct{}) when is_auction(struct) do
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
