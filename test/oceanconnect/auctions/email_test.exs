defmodule Oceanconnect.EmailTest do
	use Oceanconnect.DataCase

	alias Oceanconnect.Auctions.{Auction, Email}
	alias Oceanconnect.Accounts

	setup do
		auction = insert(:auction)
		buyer_company = Accounts.get_company!(auction.buyer_id)
		buyer = insert(:user, %{company: buyer_company})

		supplier_companies = auction.suppliers
		suppliers = Accounts.users_for_companies(supplier_companies)

		{:ok, %{suppliers: suppliers, buyer: Accounts.get_user!(buyer.id), auction: auction}}
	end

	describe "emails" do
		test "auction invitation email builds for supplier", %{suppliers: suppliers, auction: auction} do
			for supplier <- suppliers do
				email = Email.auction_invitation(supplier, auction)

				assert email.to == supplier
				assert email.subject == "You have been invited to an auction."
				assert email.html_body =~ "Auction Invitation"
			end
		end

		test "auction invitation email does not build for buyers", %{buyer: buyer, auction: auction} do
			email = Email.auction_invitation(buyer, auction)

			assert email == nil
		end

		test "auction starting soon email builds for all participants", %{suppliers: suppliers, buyer: buyer, auction: auction} do
			for supplier <- suppliers do
				supplier_email = Email.auction_starting_soon(supplier, auction)

				assert supplier_email.to == supplier
				assert supplier_email.subject == "Auction starting soon."
				assert supplier_email.html_body =~ "Auction Starting Soon"
			end

			buyer_email = Email.auction_starting_soon(buyer, auction)

			assert buyer_email.to == [buyer]
			assert buyer_email.subject == "Your auction is starting soon."
			assert buyer_email.html_body =~ "Auction Starting Soon"
		 end

		test "auction starting email builds for all participants", %{suppliers: suppliers, auction: auction} do
			
		end
	end
end
