defmodule OceanconnectWeb.EmailController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Repo
  alias OceanconnectWeb.Email
  alias OceanconnectWeb.Mailer

  def send_invitation(conn, _) do
    auction = Oceanconnect.Auctions.get_auction!(1) |> Oceanconnect.Auctions.fully_loaded
    supplier_emails = Email.auction_invitation(auction)
    for email <- supplier_emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end

  def send_upcoming(conn, _) do
    auction = Oceanconnect.Auctions.get_auction(1) |> Oceanconnect.Auctions.fully_loaded
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} = Email.auction_starting_soon(auction)
    emails = List.flatten([supplier_emails, buyer_emails])
    for email <- emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end

  def send_cancellation(conn, _) do
    auction = Oceanconnect.Auctions.get_auction!(1) |> Oceanconnect.Auctions.fully_loaded
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} = Email.auction_canceled(auction)
    emails = List.flatten([supplier_emails | buyer_emails])
    for email <- emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
  end

  def send_completion(conn, _) do
    auction = Oceanconnect.Auctions.get_auction!(1) |> Oceanconnect.Auctions.fully_loaded
    winning_supplier_company = Oceanconnect.Accounts.get_company!(1)
    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails} = Email.auction_closed(200, auction.fuel_quantity * 200, winning_supplier_company, auction)
    emails = List.flatten([supplier_emails | buyer_emails])
    for email <- emails do
      Mailer.deliver_now(email)
    end

    conn
    |> redirect(to: "/sent_emails")
   end
end
