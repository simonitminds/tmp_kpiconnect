defmodule OceanconnectWeb.ClaimView do
  use OceanconnectWeb, :view

  alias Oceanconnect.Auctions

  def options_for_fixture_select(fixtures) do
    fixture_options =
      fixtures
      |> Enum.map(fn f ->
        {"#{f.supplier.name} | #{f.vessel.name} | #{f.fuel.name}", f.id}
      end)

    [{"Select a fixture to claim against", nil}] ++ fixture_options
  end

  def options_for_supplier_select(fixtures) do
    suppliers =
      Enum.map(fixtures, & &1.supplier)
      |> Enum.uniq_by(& &1.id)

    [{"Select a supplier", nil}] ++ Enum.map(suppliers, &{&1.name, &1.id})
  end

  def options_for_vessel_select(fixtures) do
    vessels =
      Enum.map(fixtures, & &1.vessel)
      |> Enum.uniq_by(& &1.id)

    [{"Select a vessel", nil}] ++ Enum.map(vessels, &{&1.name, &1.id})
  end

  def options_for_fuel_select(fixtures) do
    fuels =
      Enum.map(fixtures, & &1.fuel)
      |> Enum.uniq_by(& &1.id)

    [{"Select a fuel", nil}] ++ Enum.map(fuels, &{&1.name, &1.id})
  end

  def options_for_barge_select(fixtures, auction) do
    barges =
      Enum.map(fixtures, & &1.supplier)
      |> Enum.uniq_by(& &1.id)
      |> Auctions.approved_barges_for_winning_suppliers(auction)
      |> Enum.map(& &1.barge)

    case barges do
      [] ->
        [{"Select a barge", nil}]

      _ ->
        [{"Select a barge", nil}] ++ Enum.map(barges, &{&1.name, &1.id})
    end
  end

  def vessel_name_list(vessels) do
    vessels
    |> Enum.map(& &1.name)
    |> Enum.join(", ")
  end

  def format_decimal(decimal) do
    decimal
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 3)

    "#{decimal}"
  end

  def format_price(amounts) when is_list(amounts) do
    Enum.map(amounts, &format_price/1)
    |> Enum.join(", ")
  end

  def format_price(amount) do
    case amount do
      amount when is_float(amount) ->
        amount = :erlang.float_to_binary(amount, decimals: 2)
        "$#{amount}"

      %Decimal{} = amount ->
        amount =
          amount
          |> Decimal.to_float()
          |> :erlang.float_to_binary(decimals: 2)

        "$#{amount}"

      _ ->
        amount
    end
  end

  def convert_date?(datetime, default \\ "—")

  def convert_date?(date_time = %{}, _default) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)} GMT"
    date = "#{leftpad(date_time.day)} #{month_abbreviation(date_time.month)} #{date_time.year}"
    "#{date} #{time}"
  end

  def convert_date?(_, default), do: default

  def month_abbreviation(month) when month >= 1 and month <= 12 do
    Enum.at(
      ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
      month - 1
    )
  end

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
