defmodule OceanconnectWeb.Email do
	import Bamboo.Email

	alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.Company
	alias Oceanconnect.Auctions.Auction

	def auction_invitation(%Auction{suppliers: supplier_companies}) do
    suppliers = Accounts.users_for_companies(supplier_companies)

    Enum.map(suppliers, fn(supplier) ->
      base_email(supplier)
      |> subject("You have been invited to an auction.")
      |> html_body("<strong>Auction Invitation</strong>")
      |> text_body("You have been invited to an auction on Oceanconnect Marine.")
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

  def auction_closed(winning_supplier_company = %Company{}, %Auction{buyer_id: buyer_id}) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies([winning_supplier_company])

    supplier_emails =
      Enum.map(suppliers, fn(supplier) ->
        base_email(supplier)
        |> subject("You have won the auction!")
        |> html_body("<strong>Auction Won</strong>")
        |> text_body("You have won the auction!")
      end)
    buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction has closed.")
        |> html_body("<strong>Auction Closed</strong>")
        |> text_body("Your auction has closed.")
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  def auction_canceled(%Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyers = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

    # TODO: pass buyer_company as assigns in this
		supplier_emails =
			Enum.map(suppliers, fn(supplier) ->
				base_email(supplier)
				|> subject("Auction canceled.")
				|> html_body("<strong>Auction Canceled</strong>")
				|> text_body("An auction that you have been invited to has been canceled.")
			end)
		buyer_emails =
      Enum.map(buyers, fn(buyer) ->
        base_email(buyer)
        |> subject("Your auction has been canceled.")
        |> html_body("<strong>Auction Canceled</strong>")
        |> text_body("Your auction has canceled.")
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

	defp base_email(user) do
		new_email()
		|> from("oceanconnect@example.com")
    |> to(user)
	end
end
