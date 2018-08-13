defmodule Oceanconnect.Auctions.Email do
	import Bamboo.Email

	alias Oceanconnect.Accounts
	alias Oceanconnect.Accounts.User
	alias Oceanconnect.Auctions.Auction

	def auction_invitation(user = %User{company_id: company_id}, %Auction{buyer_id: buyer_id}) do
		case company_id == buyer_id do
			true -> nil
			false ->
				base_email
				|> to(user)
				|> subject("You have been invited to an auction.")
				|> html_body("<strong>Auction Invitation</strong>")
				|> text_body("You have been invited to an auction on Oceanconnect Marine.")
		end
	end

	def auction_starting_soon(user = %User{}, %Auction{suppliers: supplier_companies, buyer_id: buyer_id}) do
		buyer_company = Accounts.get_company!(buyer_id)
		buyer = Accounts.users_for_companies([buyer_company])
		suppliers = Accounts.users_for_companies(supplier_companies)

		supplier_email =
			base_email
		  |> bcc(suppliers)
			|> subject("Auction starting soon.")
			|> html_body("<strong>Auction Starting Soon</strong>")
			|> text_body("An auction that you have been invited to is starting soon.")
		buyer_email =
		  base_email
		  |> to(buyer)
			|> subject("Your auction is starting soon.")
			|> html_body("<strong>Auction Starting Soon</strong>")
			|> text_body("Your auction is starting soon.")

		case user in suppliers do
			true -> supplier_email
			false -> buyer_email
		end
	end

	def auction_starting(user) do
		base_email
		|> to(user)
		|> subject("Auction starting.")
		|> html_body("<strong>Auction Starting</strong>")
		|> text_body("An auction that you have been invited to is starting.")
	end

	def first_bid_placed(user) do
		base_email
		|> to(user)
		|> subject("First bid placed.")
		|> html_body("<strong>First Bid Placed</strong>")
		|> text_body("The first bid has been placed in an auction you are participating.")
	end

	def losing_bid(user) do
		base_email
		|> to(user)
		|> subject("You have been outbid.")
		|> html_body("<strong>You have been outbid!</strong>")
		|> text_body("Your highest bid has been beaten by another participant.")
	end

	def winning_bid(user) do
		base_email
		|> to(user)
		|> subject("You have the winning bid.")
		|> html_body("<strong>You are in the lead!</strong>")
		|> text_body("You are currently the highest bidder in the auction.")
	end

	def tied_bid(user) do
		base_email
		|> to(user)
		|> subject("Your bid is tied.")
		|> html_body("<strong>You are tied for the lead!</strong>")
		|> text_body("Your highest bid is currently tied with another participant's highest bid.")
	end

	def auction_ending_soon(user) do
		base_email
		|> to(user)
		|> subject("Auction ending soon.")
		|> html_body("<strong>Auction Ending Soon</strong>")
		|> text_body("An auction that you are a participant in is ending soon.")
	end

	def auction_ending(user) do
		base_email
		|> to(user)
		|> subject("Auction ending.")
		|> html_body("<strong>Auction Ending</strong>")
		|> text_body("An auction that you are a participant in is ending.")
	end

	def auction_won(user) do
		base_email
		|> to(user)
		|> subject("Auction won!")
		|> html_body("<strong>You have won the auction!</strong>")
		|> text_body("Your bid was chosen as the best solution by the buyer.")
	end

	def auction_lost do

	end

	defp base_email do
		new_email
		|> from("oceanconnect@example.com")
	end
end
