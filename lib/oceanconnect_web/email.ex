defmodule OceanconnectWeb.Email do
  import Bamboo.Email
  use Bamboo.Phoenix, view: OceanconnectWeb.EmailView

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction

  def auction_invitation(auction = %Auction{}) do
    auction = Auctions.fully_loaded(auction)

    %Auction{
      buyer: buyer,
      port: port,
      suppliers: supplier_companies,
      vessels: vessels
    } = auction

    suppliers = Accounts.users_for_companies(supplier_companies)

    vessel_name_list =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    port_name = port.name

    Enum.map(suppliers, fn supplier ->
      base_email(supplier)
      |> subject(
        "You have been invited to Auction #{auction.id} for #{vessel_name_list} at #{port_name}"
      )
      |> render(
        "auction_invitation.html",
        supplier: supplier,
        auction: auction,
        buyer_company: buyer
      )
    end)
  end

  def auction_rescheduled(auction = %Auction{}) do
    auction = Auctions.fully_loaded(auction)

    %Auction{
      buyer: buyer,
      port: port,
      suppliers: supplier_companies,
      vessels: vessels
    } = auction

    suppliers = Accounts.users_for_companies(supplier_companies)

    vessel_name_list =
      vessels
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    port_name = port.name

    Enum.map(suppliers, fn supplier ->
      base_email(supplier)
      |> subject(
        "The start time for Auction #{auction.id} for #{vessel_name_list} at #{port_name} has been changed"
      )
      |> render(
        "auction_updated.html",
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
        auction = %Auction{},
        active_participants
      ) do
    auction = Auctions.fully_loaded(auction)

    %Auction{
      buyer_id: buyer_id,
      auction_vessel_fuels: vessel_fuels,
      port: port
    } = auction

    active_user_emails =
      active_participants
      |> Enum.map(& &1.email)

    buyer_company = Accounts.get_company!(buyer_id)

    buyers =
      Accounts.users_for_companies([buyer_company])
      |> Enum.filter(&(&1.email in active_user_emails))

    port_name = port.name

    bids_by_vessel =
      Enum.reduce(bids, %{}, fn bid, acc ->
        vessel_fuel = Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
        if vessel_fuel do
          case acc[vessel_fuel.vessel] do
            nil ->
              Map.put(acc, vessel_fuel.vessel, [bid])

            existing_value ->
              Map.put(acc, vessel_fuel.vessel, [bid | existing_value])
          end
        else
          acc
        end
      end)

    Enum.flat_map(bids_by_vessel, fn {vessel, bids} ->
      bids_by_supplier =
        Enum.reduce(bids, %{}, fn bid, acc ->
          case acc[bid.supplier_id] do
            nil ->
              Map.put(acc, bid.supplier_id, [bid])

            existing_value ->
              Map.put(acc, bid.supplier_id, [bid | existing_value])
          end
        end)

      Enum.map(bids_by_supplier, fn {supplier_id, bids} ->
        supplier_company = Accounts.get_company!(supplier_id)

        suppliers =
          Accounts.users_for_companies([supplier_company])
          |> Enum.filter(&(&1.email in active_user_emails))

        is_traded_bid = Enum.any?(bids, &(&1.is_traded_bid == true))

        deliverables =
          bids
          |> Enum.map(fn bid ->
            Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
            |> Map.put(:bid, bid)
          end)

        supplier_emails =
          Enum.map(suppliers, fn supplier ->
            base_email(supplier)
            |> subject("You have won Auction #{auction.id} for #{vessel.name} at #{port_name}!")
            |> render(
              "auction_completion.html",
              user: supplier,
              winning_supplier_company: supplier_company,
              physical_buyer: buyer_company,
              is_traded_bid: is_traded_bid,
              auction: auction,
              vessel: vessel,
              buyer_company: buyer_company_for_email(is_traded_bid, buyer_company),
              deliverables: deliverables,
              approved_barges:
                approved_barges_for_supplier(approved_barges, supplier_company.id),
              is_buyer: false
            )
          end)

        buyer_emails =
          Enum.map(buyers, fn buyer ->
            base_email(buyer)
            |> subject("Auction #{auction.id} for #{vessel.name} at #{port_name} has closed.")
            |> render(
              "auction_completion.html",
              user: buyer,
              winning_supplier_company:
                supplier_company_for_email(is_traded_bid, buyer_company, supplier_company),
              physical_supplier: supplier_company,
              is_traded_bid: is_traded_bid,
              auction: auction,
              vessel: vessel,
              buyer_company: buyer_company,
              deliverables: deliverables,
              approved_barges:
                approved_barges_for_supplier(approved_barges, supplier_company.id),
              is_buyer: true
            )
          end)

        List.flatten([supplier_emails, buyer_emails])
      end)
    end)
    |> List.flatten()
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

  def password_reset(%Accounts.User{} = user, token) do
    base_email(user)
    |> subject("Reset your password")
    |> render(
      "password_reset.html",
      user: user,
      token: token
    )
  end

  def two_factor_auth(%Accounts.User{has_2fa: true} = user, one_time_pass) do
    two_factor_email(user)
    |> subject("Two factor authentication")
    |> render(
      "two_factor_auth.html",
      user: user,
      one_time_pass: one_time_pass
    )
  end

  def user_interest(new_user_info) do
    user_interest_email()
    |> subject("An unregistered user is requesting more information")
    |> render(
      "user_interest.html",
      new_user_info: new_user_info
    )
  end

  defp approved_barges_for_supplier(approved_barges, supplier_id) do
    Enum.filter(approved_barges, &(&1.supplier_id == supplier_id))
    |> Enum.uniq()
  end

  defp buyer_company_for_email(_is_traded_bid = true, %Accounts.Company{
         broker_entity_id: broker_id
       }) do
    Accounts.get_company!(broker_id)
  end

  defp buyer_company_for_email(_is_traded_bid = false, buyer_company = %Accounts.Company{}),
    do: buyer_company

  defp supplier_company_for_email(
         _is_traded_bid = true,
         %Accounts.Company{
           broker_entity_id: broker_id
         },
         _supplier_company
       ) do
    Accounts.get_company!(broker_id)
  end

  defp supplier_company_for_email(
         _is_traded_bid = false,
         _buyer_company,
         supplier_company = %Accounts.Company{}
       ),
       do: supplier_company

  defp base_email(user) do
    new_email()
    |> cc("nbolton@oceanconnectmarine.com")
    |> bcc("lauren@gaslight.co")
    |> from("bunkers@oceanconnectmarine.com")
    |> to(user)
    |> put_html_layout({OceanconnectWeb.LayoutView, "email.html"})
  end

  defp two_factor_email(user) do
    new_email()
    |> from("bunkers@oceanconnectmarine.com")
    |> to(user)
    |> put_html_layout({OceanconnectWeb.LayoutView, "email.html"})
  end

  defp user_interest_email do
    new_email()
    |> bcc("lauren@gaslight.co")
    |> from("bunkers@oceanconnectmarine.com")
    |> to("nbolton@oceanconnectmarine.com")
    |> put_html_layout({OceanconnectWeb.LayoutView, "email.html"})
  end
end
