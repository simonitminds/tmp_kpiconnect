defmodule Oceanconnect.EmailTest do
	use Oceanconnect.DataCase

	alias Oceanconnect.Auctions.Email
	alias Oceanconnect.Accounts

	setup do
		auction = insert(:auction)
		buyer_company = Accounts.get_company!(auction.buyer_id)
		buyers = [insert(:user, %{company: buyer_company}), insert(:user, %{company: buyer_company})]

		supplier_companies = auction.suppliers
    winning_supplier_company = Enum.at(Enum.take_random(supplier_companies, 1), 0)
		Enum.each(supplier_companies, fn(supplier_company) ->
			insert(:user, %{company: supplier_company})
		end)
		suppliers = Accounts.users_for_companies(supplier_companies)
    winning_suppliers = Accounts.users_for_companies([winning_supplier_company])
		{:ok, %{suppliers: suppliers, buyers: buyers, auction: auction, winning_supplier_company: winning_supplier_company, winning_suppliers: winning_suppliers}}
	end

	describe "emails" do
		test "auction invitation email builds for suppliers", %{suppliers: suppliers, auction: auction} do
      supplier_emails = Email.auction_invitation(auction)
			for supplier <- suppliers, do: assert Enum.any?(supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- supplier_emails do
				assert supplier_email.subject == "You have been invited to an auction."
				assert supplier_email.html_body =~ "Auction Invitation"
			end
		end

		test "auction invitation email does not build for buyers", %{buyers: buyers, auction: auction} do
	    emails = Email.auction_invitation(auction)
      for buyer <- buyers, do: refute Enum.any?(emails, fn(email) -> email.to.id == buyer.id end)
		end

		test "auction starting soon email builds for all participants", %{suppliers: suppliers, buyers: buyers, auction: auction} do
			supplier_emails = Email.auction_starting_soon(auction).supplier_emails
			for supplier <- suppliers, do: assert Enum.any?(supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- supplier_emails do
        assert supplier_email.subject == "Auction starting soon."
				assert supplier_email.html_body =~ "Auction Starting Soon"
      end

      buyer_emails = Email.auction_starting_soon(auction).buyer_emails
      for buyer <- buyers, do: assert Enum.any?(buyer_emails, fn(buyer_email) -> buyer_email.to.id == buyer.id end)
      for buyer_email <- buyer_emails do
        assert buyer_email.subject == "Your auction is starting soon."
        assert buyer_email.html_body =~ "Auction Starting Soon"
      end
		end

		test "auction starting email builds for all participants", %{suppliers: suppliers, buyers: buyers, auction: auction} do
      supplier_emails = Email.auction_started(auction).supplier_emails
      for supplier <- suppliers, do: assert Enum.any?(supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- supplier_emails do
				assert supplier_email.subject == "Auction started."
				assert supplier_email.html_body =~ "Auction Started"
      end

			buyer_emails = Email.auction_started(auction).buyer_emails
      for buyer <- buyers, do: assert Enum.any?(buyer_emails, fn(buyer_email) -> buyer_email.to.id == buyer.id end)
      for buyer_email <- buyer_emails do
			  assert buyer_email.subject == "Your auction has started."
			  assert buyer_email.html_body =~ "Auction Started"
      end
		end

    test "auction ending soon email builds for all participants", %{suppliers: suppliers, buyers: buyers, auction: auction} do
      supplier_emails = Email.auction_ending_soon(auction).supplier_emails
      for supplier <- suppliers, do: assert Enum.any?(supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- supplier_emails do
				assert supplier_email.subject == "Auction ending soon."
				assert supplier_email.html_body =~ "Auction Ending Soon"
      end

			buyer_emails = Email.auction_ending_soon(auction).buyer_emails
      for buyer <- buyers, do: assert Enum.any?(buyer_emails, fn(buyer_email) -> buyer_email.to.id == buyer.id end)
      for buyer_email <- buyer_emails do
			  assert buyer_email.subject == "Your auction is ending soon."
			  assert buyer_email.html_body =~ "Auction Ending Soon"
      end
    end

    test "auction ending email builds for all participants", %{suppliers: suppliers, buyers: buyers, auction: auction} do
      supplier_emails = Email.auction_ended(auction).supplier_emails
      for supplier <- suppliers, do: assert Enum.any?(supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- supplier_emails do
				assert supplier_email.subject == "Auction ended."
				assert supplier_email.html_body =~ "Auction Ended"
      end

			buyer_emails = Email.auction_ended(auction).buyer_emails
      for buyer <- buyers, do: assert Enum.any?(buyer_emails, fn(buyer_email) -> buyer_email.to.id == buyer.id end)
      for buyer_email <- buyer_emails do
			  assert buyer_email.subject == "Your auction has ended."
			  assert buyer_email.html_body =~ "Auction Ended"
      end
    end

    test "auction completion email builds for winning supplier and buyer", %{winning_supplier_company: winning_supplier_company, buyers: buyers, auction: auction, winning_suppliers: winning_suppliers} do
      winning_supplier_emails= Email.auction_closed(winning_supplier_company, auction).supplier_emails
      for supplier <- winning_suppliers, do: assert Enum.any?(winning_supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- winning_supplier_emails do
        assert supplier_email.subject == "You have won the auction!"
        assert supplier_email.html_body =~ "Auction Won"
      end

      buyer_emails = Email.auction_closed(winning_supplier_company, auction).buyer_emails
      for buyer <- buyers, do: assert Enum.any?(buyer_emails, fn(buyer_email) -> buyer_email.to.id == buyer.id end)
      for buyer_email <- buyer_emails do
        assert buyer_email.subject == "Your auction has closed."
        assert buyer_email.html_body =~ "Auction Closed"
      end
    end

    test "auction cancellation email builds for all participants", %{suppliers: suppliers, buyers: buyers, auction: auction} do
      supplier_emails = Email.auction_canceled(auction).supplier_emails
      for supplier <- suppliers, do: Enum.any?(supplier_emails, fn(supplier_email) -> supplier_email.to.id == supplier.id end)
      for supplier_email <- supplier_emails do
        assert supplier_email.subject == "Auction canceled."
        assert supplier_email.html_body =~ "Auction Canceled"
      end

			buyer_emails = Email.auction_canceled(auction).buyer_emails
      for buyer <- buyers, do: assert Enum.any?(buyer_emails, fn(buyer_email) -> buyer_email.to.id == buyer.id end)
      for buyer_email <- buyer_emails do
			  assert buyer_email.subject == "Your auction has been canceled."
			  assert buyer_email.html_body =~ "Auction Canceled"
      end
    end
	end
end
