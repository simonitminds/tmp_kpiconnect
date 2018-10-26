defmodule OceanconnectWeb.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBid}

  def auction_invitation(
        auction = %Auction{
          suppliers: supplier_companies,
          buyer_id: _buyer_id,
          buyer: buyer,
          vessels: vessels,
          port: port
        }
      ) do
    suppliers = Accounts.users_for_companies(supplier_companies)
    vessel_name = vessels
    |> Enum.map(&(&1.name))
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

  def auction_starting_soon(
        auction = %Auction{
          suppliers: supplier_companies,
          buyer: buyer_company,
          vessels: vessels,
          port: port
        }
      ) do
    buyers = buyer_company.users
    vessel_name = vessels
    |> Enum.map(&(&1.name))
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
        auction = %Auction{buyer_id: buyer_id, vessels: vessels, port: port}
      ) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    vessel_name = vessels
    |> Enum.map(&(&1.name))
    |> Enum.join(", ")
    port_name = port.name

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
            winning_solution_bids: product_bids_for_supplier(bids, supplier_company.id),
            approved_barges: approved_barges_for_supplier(approved_barges, supplier.id),
            is_buyer: false
          )
        end)
      end)

    buyer_emails =
      Enum.flat_map(bids, fn bid ->
        %{buyer_id: buyer_id} = Auctions.get_auction!(bid.auction_id)
        buyer_company = Accounts.get_company!(buyer_id)
        Enum.map(buyers, fn buyer ->
          base_email(buyer)
          |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} has closed.")
          |> render(
            "auction_completion.html",
            user: buyer,
            winning_supplier_company: supplier_company_for_bid(bid),
            auction: auction,
            buyer_company: buyer_company,
            winning_solution_bids: product_bids_for_buyer(bids),
            approved_barges: approved_barges,
            is_buyer: true
          )
        end)
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  def product_bids_for_supplier(bids, supplier_id) do
    Enum.filter(bids, &(&1.supplier_id == supplier_id))
    |> Enum.group_by(&(&1.fuel_id))
  end

  def approved_barges_for_supplier(approved_barges, supplier_id) do
    Enum.filter(approved_barges, &(&1.supplier_id == supplier_id))
    |> Enum.uniq()
  end

  def product_bids_for_buyer(bids) do
    Enum.group_by(bids, &(&1.fuel_id))
  end

  def buyer_company_for_bid(%AuctionBid{is_traded_bid: true}) do
    Accounts.get_ocm_company()
  end
  def buyer_company_for_bid(%AuctionBid{auction_id: auction_id}) do
    %{buyer_id: buyer_id} = Auctions.get_auction!(auction_id)
    Accounts.get_company!(buyer_id)
  end

  # def buyer_company_for_bids(bids) when is_list(bids), do: Enum.map(bids, &buyer_company_for_bid/1)

  def supplier_company_for_bid(%AuctionBid{is_traded_bid: true}) do
    Accounts.get_ocm_company()
  end
  def supplier_company_for_bid(%AuctionBid{supplier_id: supplier_id}) do
    Accounts.get_company!(supplier_id)
  end

  # def supplier_companies_for_bids(bids) when is_list(bids), do: Enum.map(bids, &supplier_company_for_bid/1)

  def auction_canceled(
        auction = %Auction{
          suppliers: supplier_companies,
          buyer_id: buyer_id,
          vessels: vessels,
          port: port
        }
      ) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies(supplier_companies)
    vessel_name = vessels
    |> Enum.map(&(&1.name))
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

  defp base_email(user) do
    new_email()
    |> cc("nbolton@oceanconnectmarine.com")
    |> bcc("lauren@gaslight.co")
    |> from("bunkers@oceanconnectmarine.com")
    |> to(user)
    |> put_html_layout({OceanconnectWeb.LayoutView, "email.html"})
  end
end
