defmodule Oceanconnect.Notifications.Emails.ClaimCreatedTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)

    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company]
      )
      |> Auctions.fully_loaded()

    {:ok, fixtures} =
      close_auction!(auction)
      |> Auctions.create_fixtures_from_state()

    fixture =
      hd(fixtures)
      |> Oceanconnect.Repo.preload([:vessel, :fuel, :supplier])

    {:ok, %{fixture: fixture, auction: auction, buyer_company: buyer_company}}
  end

  describe "quantity claims" do
    setup %{fixture: fixture, auction: auction, buyer_company: buyer_company} do
      claim =
        insert(
          :claim,
          type: "quantity",
          fixture: fixture,
          quantity_missing: 100,
          price_per_unit: 100,
          additional_information: "Your fuel sucked",
          auction: auction,
          receiving_vessel: fixture.vessel,
          delivered_fuel: fixture.fuel,
          supplier: fixture.supplier,
          buyer: buyer_company,
          notice_recipient_type: "supplier",
          notice_recipient: fixture.supplier
        )

      {:ok, %{claim: claim, fixture: fixture, auction: auction}}
    end

    test "generate/1 creates emails for a quantity claim", %{
      claim: claim,
      fixture: fixture,
      auction: auction
    } do
      emails = Emails.ClaimCreated.generate(claim)

      for email <- emails do
        assert email.subject == "A Quantity Claim has been made for Auction #{auction.id}"

        assert email.html_body =~
                 "#{OceanconnectWeb.ClaimView.format_decimal(claim.quantity_missing)}"

        assert email.html_body =~
                 "#{OceanconnectWeb.ClaimView.format_price(claim.total_fuel_value)}"

        assert email.html_body =~ fixture.vessel.name
        assert email.html_body =~ claim.supplier.name
        assert email.html_body =~ claim.buyer.name
        assert email.html_body =~ claim.auction.port.name
        assert email.html_body =~ claim.buyer.contact_name
      end
    end
  end

  describe "density claims" do
    setup %{fixture: fixture, auction: auction, buyer_company: buyer_company} do
      claim =
        insert(
          :claim,
          type: "density",
          fixture: fixture,
          quantity_difference: 100,
          price_per_unit: 100,
          additional_information: "Your fuel sucked",
          auction: auction,
          receiving_vessel: fixture.vessel,
          delivered_fuel: fixture.fuel,
          supplier: fixture.supplier,
          buyer: buyer_company,
          notice_recipient_type: "supplier",
          notice_recipient: fixture.supplier
        )

      {:ok, %{claim: claim, fixture: fixture, auction: auction}}
    end

    test "generate/1 creates emails for a density claim", %{
      claim: claim,
      fixture: fixture,
      auction: auction
    } do
      emails = Emails.ClaimCreated.generate(claim)

      for email <- emails do
        assert email.subject == "A Density Claim has been made for Auction #{auction.id}"

        assert email.html_body =~
                 "#{OceanconnectWeb.ClaimView.format_decimal(claim.quantity_difference)}"

        assert email.html_body =~
                 "#{OceanconnectWeb.ClaimView.format_price(claim.total_fuel_value)}"

        assert email.html_body =~ fixture.vessel.name
        assert email.html_body =~ claim.supplier.name
        assert email.html_body =~ claim.buyer.name
        assert email.html_body =~ claim.auction.port.name
        assert email.html_body =~ claim.buyer.contact_name
      end
    end
  end

  describe "quality claims" do
    setup %{fixture: fixture, auction: auction, buyer_company: buyer_company} do
      claim =
        insert(
          :claim,
          type: "quality",
          fixture: fixture,
          quality_description: "Your fuel really, really sucked...",
          additional_information: "Your fuel sucked",
          auction: auction,
          receiving_vessel: fixture.vessel,
          delivered_fuel: fixture.fuel,
          supplier: fixture.supplier,
          buyer: buyer_company,
          notice_recipient_type: "supplier",
          notice_recipient: fixture.supplier
        )

      {:ok, %{claim: claim, fixture: fixture, auction: auction}}
    end

    test "generate/1 creats emails for a quality claim", %{
      claim: claim,
      fixture: fixture,
      auction: auction
    } do
      emails = Emails.ClaimCreated.generate(claim)

      for email <- emails do
        assert email.subject == "A Quality Claim has been made for Auction #{auction.id}"
        assert email.html_body =~ claim.quality_description
        assert email.html_body =~ fixture.vessel.name
        assert email.html_body =~ claim.supplier.name
        assert email.html_body =~ claim.buyer.name
        assert email.html_body =~ claim.auction.port.name
        assert email.html_body =~ claim.buyer.contact_name
      end
    end
  end
end
