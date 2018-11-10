defmodule OceanconnectWeb.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBid}

  def auction_invitation(auction = %Auction{}) do
    auction = Auctions.fully_loaded(auction)
    %Auction{
        buyer: buyer,
        port: port,
        suppliers: supplier_companies,
        vessels: vessels
      } = auction

    suppliers = Accounts.users_for_companies(supplier_companies)
    vessel_name =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")
    port_name = port.name

    Enum.map(suppliers, fn supplier ->
      base_email(supplier)
      |> subject(
        "You have been invited to Auction #{auction.id} for #{vessel_name} at #{port_name}"
      )
      |> render(
        "auction_invitation.html",
        supplier: supplier,
        auction: auction,
        buyer_company: buyer
      )
    end)
  end

  def auction_starting_soon(auction = %Auction{}) do
    auction = Auctions.fully_loaded(auction)
    %Auction{
        suppliers: supplier_companies,
        buyer: buyer_company,
        vessels: vessels,
        port: port
      } = auction

    buyers = buyer_company.users
    vessel_name =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")
    port_name = port.name
    suppliers =
      Enum.map(supplier_companies, fn supplier_company ->
        Enum.map(supplier_company.users, fn user -> user end)
      end)
      |> List.flatten()

    supplier_emails =
      Enum.map(suppliers, fn supplier ->
        base_email(supplier)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} is starting soon.")
        |> render(
          "auction_starting.html",
          user: supplier,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: false
        )
      end)

    buyer_emails =
      Enum.map(buyers, fn buyer ->
        base_email(buyer)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} is starting soon.")
        |> render(
          "auction_starting.html",
          user: buyer,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: true
        )
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  def auction_closed(
        bids,
        approved_barges,
        auction = %Auction{}
      ) do
    auction = Auctions.fully_loaded(auction)
    %Auction{
        buyer_id: buyer_id,
        vessels: vessels,
        auction_vessel_fuels: vessel_fuels,
        port: port
      } = auction
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    vessel_name =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")
    port_name = port.name

    deliverables =
      vessel_fuels
      |> Enum.map(fn(vessel_fuel) ->
        bid_for_vessel_fuel = Enum.find(bids, &(&1.fuel_id == "#{vessel_fuel.fuel_id}"))
        Map.put(vessel_fuel, :bid, bid_for_vessel_fuel)
      end)

    supplier_emails =
      Enum.flat_map(bids, fn bid ->
        supplier_company = Accounts.get_company!(bid.supplier_id)
        suppliers = Accounts.users_for_companies([supplier_company])

        Enum.map(suppliers, fn supplier ->
          base_email(supplier)
          |> subject("You have won Auction #{auction.id} for #{vessel_name} at #{port_name}!")
          |> render(
            "auction_completion.html",
            user: supplier,
            winning_supplier_company: supplier_company,
            auction: auction,
            buyer_company: buyer_company_for_bid(bid),
            deliverables: deliverables_for_supplier(deliverables, supplier_company.id),
            approved_barges: approved_barges_for_supplier(approved_barges, supplier_company.id),
            is_buyer: false
          )
        end)
      end)

    buyer_emails =
      Enum.flat_map(bids, fn bid ->
        Enum.map(buyers, fn buyer ->
          supplier_company = Accounts.get_company!(bid.supplier_id)

          base_email(buyer)
          |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} has closed.")
          |> render(
            "auction_completion.html",
            user: buyer,
            winning_supplier_company: supplier_company_for_bid(bid),
            auction: auction,
            buyer_company: buyer_company,
            deliverables: deliverables_for_supplier(deliverables, supplier_company.id),
            approved_barges: approved_barges,
            is_buyer: true
          )
        end)
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  def auction_canceled(auction = %Auction{}) do
    auction = Auctions.fully_loaded(auction)
    %Auction{
          suppliers: supplier_companies,
          buyer_id: buyer_id,
          vessels: vessels,
          port: port
        } = auction
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies(supplier_companies)
    vessel_name =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")
    port_name = port.name

    supplier_emails =
      Enum.map(suppliers, fn supplier ->
        base_email(supplier)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} cancelled.")
        |> render(
          "auction_cancellation.html",
          user: supplier,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: false
        )
      end)

    buyer_emails =
      Enum.map(buyers, fn buyer ->
        base_email(buyer)
        |> subject("You have canceled Auction #{auction.id} for #{vessel_name} at #{port_name}.")
        |> render(
          "auction_cancellation.html",
          user: buyer,
          auction: auction,
          buyer_company: buyer_company,
          is_buyer: true
        )
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  defp deliverables_for_supplier(deliverables, supplier_id) do
    deliverables
    |> Enum.filter(&(&1.bid.supplier_id == supplier_id))
  end

  defp approved_barges_for_supplier(approved_barges, supplier_id) do
    Enum.filter(approved_barges, &(&1.supplier_id == supplier_id))
    |> Enum.uniq()
  end

  defp buyer_company_for_bid(%AuctionBid{is_traded_bid: true}) do
    Accounts.get_ocm_company()
  end
  defp buyer_company_for_bid(%AuctionBid{auction_id: auction_id}) do
    %{buyer_id: buyer_id} = Auctions.get_auction!(auction_id)
    Accounts.get_company!(buyer_id)
  end

  defp supplier_company_for_bid(%AuctionBid{is_traded_bid: true}) do
    Accounts.get_ocm_company()
  end
  defp supplier_company_for_bid(%AuctionBid{supplier_id: supplier_id}) do
    Accounts.get_company!(supplier_id)
  end

  defp base_email(user) do
    new_email()
    |> cc("nbolton@oceanconnectmarine.com")
    |> bcc("lauren@gaslight.co")
    |> from("bunkers@oceanconnectmarine.com")
    |> to(user)
    |> put_html_layout({OceanconnectWeb.LayoutView, "email.html"})
  end
end
