defmodule Oceanconnect.Notifications.Email do
  defmacro __using__(_module) do
    quote do
      import Bamboo.Email
      use Bamboo.Phoenix, view: OceanconnectWeb.EmailView
      alias Oceanconnect.Accounts
      alias Oceanconnect.Accounts.Company

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

      defp approved_barges_for_supplier(approved_barges, supplier_id) do
        Enum.filter(approved_barges, &(&1.supplier_id == supplier_id))
        |> Enum.uniq()
      end

      defp buyer_company_for_email(_is_traded_bid = true, %Company{
      broker_entity_id: broker_id
    }) do
        Accounts.get_company!(broker_id)
      end

      defp buyer_company_for_email(_is_traded_bid = false, buyer_company = %Company{}),
        do: buyer_company

      defp supplier_company_for_email(
        _is_traded_bid = true,
        %Company{
          broker_entity_id: broker_id
        },
        _supplier_company
      ) do
        Accounts.get_company!(broker_id)
      end

      defp supplier_company_for_email(
        _is_traded_bid = false,
        _buyer_company,
        supplier_company = %Company{}
      ),
        do: supplier_company
    end
  end
end
