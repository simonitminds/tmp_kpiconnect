defmodule OceanconnectWeb.Email do
	import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView

	alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.Company
	alias Oceanconnect.Auctions.Auction

	def auction_invitation(auction = %Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
    buyer_company = Accounts.get_company!(buyer_id)
    suppliers = Accounts.users_for_companies(supplier_companies)

    Enum.map(suppliers, fn(supplier) ->
      base_email(supplier)
      |> subject("You have been invited to an auction.")
      |> render("auction_invitation.html", supplier: supplier, auction: auction, buyer_company: buyer_company)
    end)
	end

	def auction_starting_soon(%Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyers = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

    # pass buyer_company as assigns in this
		supplier_emails =
			Enum.map(suppliers, fn(supplier) ->
				base_email(supplier)
				|> subject("Auction starting soon.")
				|> html_body("<strong>Auction Starting Soon</strong>")
				|> text_body("An auction that you have been invited to is starting soon.")
			end)
		buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction is starting soon.")
        |> html_body("<strong>Auction Starting Soon</strong>")
        |> text_body("Your auction is starting soon.")
      end)

     %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
	end

	def auction_started(%Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyers = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

		supplier_emails =
			Enum.map(suppliers, fn(supplier) ->
				base_email(supplier)
				|> subject("Auction started.")
				|> html_body("<strong>Auction Started</strong>")
				|> text_body("An auction that you have been invited to has started.")
			end)
		buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction has started.")
        |> html_body("<strong>Auction Started</strong>")
        |> text_body("Your auction has started.")
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
	end

	def auction_ending_soon(%Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyers = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

    # pass buyer_company as assigns in this
		supplier_emails =
			Enum.map(suppliers, fn(supplier) ->
				base_email(supplier)
				|> subject("Auction ending soon.")
				|> html_body("<strong>Auction Ending Soon</strong>")
				|> text_body("An auction that you have been invited to is ending soon.")
			end)
		buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction is ending soon.")
        |> html_body("<strong>Auction Ending Soon</strong>")
        |> text_body("Your auction is ending soon.")
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
	end

	def auction_ended(%Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyers = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

    # TODO: pass buyer_company as assigns in this
		supplier_emails =
			Enum.map(suppliers, fn(supplier) ->
				base_email(supplier)
				|> subject("Auction ended.")
				|> html_body("<strong>Auction Ended</strong>")
				|> text_body("An auction that you have been invited to has ended.")
			end)
		buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction has ended.")
        |> html_body("<strong>Auction Ended</strong>")
        |> text_body("Your auction has ended.")
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
	end

  def auction_closed(bid_amount, total_price, winning_supplier_company = %Company{}, auction = %Auction{buyer_id: buyer_id}) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies([winning_supplier_company])
    supplier_emails =
      Enum.map(suppliers, fn(supplier) ->
        base_email(supplier)
        |> subject("You have won the auction!")
        |> render("auction_completion.html", user: supplier, winning_supplier_company: winning_supplier_company, auction: auction, buyer_company: buyer_company, bid_amount: bid_amount, total_price: total_price)
      end)
    buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction has closed.")
        |> render("auction_completion.html", user: buyer, winning_supplier_company: winning_supplier_company, auction: auction, buyer_company: buyer_company, bid_amount: bid_amount, total_price: total_price)
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  def auction_canceled(auction = %Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyers = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

    # TODO: pass buyer_company as assigns in this
		supplier_emails =
			Enum.map(suppliers, fn(supplier) ->
				base_email(supplier)
				|> subject("Auction canceled.")
        |> render("auction_cancellation.html", user: supplier, auction: auction, buyer_company: buyer_company)
			end)
		buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction has been canceled.")
        |> render("auction_cancellation.html", user: buyer, auction: auction, buyer_company: buyer_company)
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

	defp base_email(user) do
		new_email()
		|> from("oceanconnect@example.com")
    |> to(user)
    |> put_html_layout({OceanconnectWeb.LayoutView, "email.html"})
	end
end
