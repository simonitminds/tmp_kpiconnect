defmodule OceanconnectWeb.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.Auction

  def auction_invitation(
        auction = %Auction{
          suppliers: supplier_companies,
          buyer: buyer,
          vessel: vessel,
          port: port
        }
      ) do
    suppliers = Accounts.users_for_companies(supplier_companies)
    vessel_name = vessel.name
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
          vessel: vessel,
          port: port
        }
      ) do
    buyers = buyer_company.users
    vessel_name = vessel.name
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
        bid_amount,
        total_price,
        winning_supplier_company = %Company{},
        auction = %Auction{buyer_id: buyer_id, vessel: vessel, port: port}
      ) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies([winning_supplier_company])
    vessel_name = vessel.name
    port_name = port.name

    supplier_emails =
      Enum.map(suppliers, fn supplier ->
        base_email(supplier)
        |> subject("You have won Auction #{auction.id} for #{vessel_name} at #{port_name}!")
        |> render(
          "auction_completion.html",
          user: supplier,
          winning_supplier_company: winning_supplier_company,
          auction: auction,
          buyer_company: buyer_company,
          bid_amount: bid_amount,
          total_price: total_price,
          is_buyer: false
        )
      end)

    buyer_emails =
      Enum.map(buyers, fn buyer ->
        base_email(buyer)
        |> subject("Auction #{auction.id} for #{vessel_name} at #{port_name} has closed.")
        |> render(
          "auction_completion.html",
          user: buyer,
          winning_supplier_company: winning_supplier_company,
          auction: auction,
          buyer_company: buyer_company,
          bid_amount: bid_amount,
          total_price: total_price,
          is_buyer: true
        )
      end)

    %{supplier_emails: supplier_emails, buyer_emails: buyer_emails}
  end

  def auction_canceled(
        auction = %Auction{
          suppliers: supplier_companies,
          buyer_id: buyer_id,
          vessel: vessel,
          port: port
        }
      ) do
    buyer_company = Accounts.get_company!(buyer_id)
    buyers = Accounts.users_for_companies([buyer_company])
    suppliers = Accounts.users_for_companies(supplier_companies)
    vessel_name = vessel.name
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
