defmodule OceanconnectWeb.EmailController do
  use OceanconnectWeb, :controller
  import Ecto.Query, only: [preload: 2]
  alias Oceanconnect.Repo

  alias OceanconnectWeb.Email
  alias OceanconnectWeb.Mailer
  alias Oceanconnect.{Auctions, Accounts}
  alias Oceanconnect.Auctions.AuctionBid

  def send_invitation(conn, _) do
    auction = Oceanconnect.Auctions.get_auction(1) |> Oceanconnect.Auctions.fully_loaded()
    supplier_emails = Email.auction_invitation(auction)

    for email <- supplier_emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end

  def send_upcoming(conn, _) do
    auction = Oceanconnect.Auctions.get_auction(1) |> Oceanconnect.Auctions.fully_loaded()

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      Email.auction_starting_soon(auction)

    emails = List.flatten([supplier_emails, buyer_emails])

    for email <- emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end

  def send_cancellation(conn, _) do
    auction = Oceanconnect.Auctions.get_auction!(1) |> Oceanconnect.Auctions.fully_loaded()

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      Email.auction_canceled(auction)

    emails = List.flatten([supplier_emails | buyer_emails])

    for email <- emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end

  def send_completion(conn, _) do
    auction = Oceanconnect.Auctions.get_auction!(3) |> Oceanconnect.Auctions.fully_loaded()
    winning_supplier_company = hd(auction.suppliers)
    winning_supplier_company2 = List.last(auction.suppliers)
    fuel_id = hd(auction.auction_vessel_fuels).fuel_id
    # barge = hd(Accounts.list_company_barges(winning_supplier_company2.id))
    # approved_barge = Map.put(barge, :approval_status, "APPROVED")
    # |> Repo.preload(:companies)
    # Auctions.submit_barge(auction, approved_barge, winning_supplier_company2.id)
    approved_barges = Auctions.list_auction_barges(auction)
    |> Enum.uniq_by(&(&1.barge_id))
    |> Enum.map(&(Map.put(&1, :supplier_id, winning_supplier_company2.id)))
    winning_solution = %{
      valid: true,
      auction_id: auction.id,
      bids: [
        %AuctionBid{
          auction_id: auction.id,
          amount: 200.00,
          fuel_id: fuel_id,
          supplier_id: winning_supplier_company2.id,
          is_traded_bid: false
        }
      ]
    }

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} =
      Email.auction_closed(
        winning_solution.bids,
        approved_barges,
        auction
      )

    emails = List.flatten([supplier_emails | buyer_emails])

    for email <- emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end
end
