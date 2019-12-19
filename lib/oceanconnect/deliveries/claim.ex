defmodule Oceanconnect.Deliveries.Claim do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.Company

  alias Oceanconnect.Deliveries.ClaimResponse
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Vessel,
    Fuel,
    Barge,
    Auction,
    AuctionFixture
  }

  @derive {Poison.Encoder,
           except: [:__meta__, :auction, :buyer, :notice_recipient, :fixture, :responses]}
  schema "claims" do
    field(:type, :string)

    field(:quantity_missing, :decimal)
    field(:quantity_difference, :decimal)
    field(:quality_description, :string)
    field(:price_per_unit, :decimal)
    field(:total_fuel_value, :decimal)

    belongs_to(:supplier, Company)
    belongs_to(:receiving_vessel, Vessel)
    belongs_to(:delivered_fuel, Fuel)
    belongs_to(:delivering_barge, Barge)

    field(:closed, :boolean, default: false)
    field(:response, :string, virtual: true)
    field(:additional_information, :string)
    field(:claim_resolution, :string)
    field(:notice_recipient_type, :string)
    field(:supplier_last_correspondence, :utc_datetime_usec)
    field(:admin_last_correspondence, :utc_datetime_usec)

    has_many(:responses, ClaimResponse)

    belongs_to(:buyer, Company)
    belongs_to(:notice_recipient, Company)

    belongs_to(:auction, Auction)
    belongs_to(:fixture, AuctionFixture)

    timestamps()
  end

  @required_fields [
    :type,
    :receiving_vessel_id,
    :delivered_fuel_id,
    :delivering_barge_id,
    :notice_recipient_id,
    :notice_recipient_type,
    :buyer_id,
    :supplier_id,
    :fixture_id,
    :price_per_unit
  ]

  @optional_fields [
    :closed,
    :response,
    :auction_id,
    :additional_information,
    :claim_resolution
  ]

  @quantity_fields [:quantity_missing]

  @density_fields [:quantity_difference]

  @quality_fields [:quality_description]

  def changeset(%__MODULE__{} = claim, attrs) do
    claim
    |> cast(
      attrs,
      @quantity_fields ++
        @density_fields ++
        @quality_fields ++
        @required_fields ++
        @optional_fields
    )
    |> maybe_add_notice_recipient()
    |> maybe_add_last_correspondence()
    |> maybe_add_total_fuel_value()
    |> maybe_validate_claim_by_type()
    |> validate_required(@required_fields, message: "This field is required.")
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:receiving_vessel_id)
    |> foreign_key_constraint(:delivered_fuel_id)
    |> foreign_key_constraint(:delivering_barge_id)
    |> foreign_key_constraint(:notice_recipient_id)
    |> foreign_key_constraint(:buyer_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fixture_id)
  end

  defp maybe_validate_claim_by_type(%Ecto.Changeset{changes: %{type: type}} = changeset) do
    case type do
      "quantity" ->
        changeset
        |> validate_required(@quantity_fields, message: "This field is required.")

      "density" ->
        changeset
        |> validate_required(@density_fields, message: "This field is required.")

      "quality" ->
        changeset
        |> validate_required(@quality_fields, message: "This field is required.")

      _ ->
        changeset
        |> add_error(:type, "Not a valid claim type: #{type}")
    end
  end

  defp maybe_validate_claim_by_type(changeset), do: changeset
  #
  # defp maybe_add_fixture(
  #        %Ecto.Changeset{
  #          changes: %{
  #            supplier_id: supplier_id,
  #            delivered_fuel_id: fuel_id,
  #            receiving_vessel_id: vessel_id
  #          }
  #        } = changeset
  #      ) do
  #   case get_field(changeset, :auction_id) || get_field(changeset, :term_auction_id) do
  #     nil ->
  #       changeset
  #
  #     auction_id ->
  #       fixtures =
  #         Auctions.get_auction!(auction_id)
  #         |> Auctions.fixtures_for_auction()
  #
  #       [fixture | _] =
  #         Enum.filter(fixtures, fn fixture ->
  #           fixture.vessel_id == vessel_id and fixture.fuel_id == fuel_id and
  #             fixture.supplier_id == supplier_id
  #         end)
  #
  #       changeset
  #       |> change(fixture_id: fixture.id)
  #   end
  # end
  #
  # defp maybe_add_fixture(changeset), do: changeset

  defp maybe_add_notice_recipient(
         %Ecto.Changeset{changes: %{supplier_id: supplier_id, notice_recipient_type: "supplier"}} =
           changeset
       ) do
    changeset
    |> change(notice_recipient_id: supplier_id)
  end

  defp maybe_add_notice_recipient(
         %Ecto.Changeset{changes: %{notice_recipient_type: "admin"}} = changeset
       ) do
    ocm = Accounts.get_ocm_company()

    changeset
    |> change(notice_recipient_id: ocm.id)
  end

  defp maybe_add_notice_recipient(changeset), do: changeset

  defp maybe_add_last_correspondence(
         %Ecto.Changeset{changes: %{notice_recipient_type: "supplier"}} = changeset
       ) do
    changeset
    |> change(supplier_last_correspondence: DateTime.utc_now())
  end

  defp maybe_add_last_correspondence(
         %Ecto.Changeset{changes: %{notice_recipient_type: "admin"}} = changeset
       ) do
    changeset
    |> change(admin_last_correspondence: DateTime.utc_now())
  end

  defp maybe_add_last_correspondence(changeset), do: changeset

  # defp validate_claim_resolution(
  #        %Ecto.Changeset{changes: %{closed: true, claim_resolution: claim_resolution}} = changeset
  #      )
  #      when is_nil(claim_resolution) or claim_resolution == "" do
  #   changeset
  #   |> add_error(
  #     :claim_resolution,
  #     "Must add resolution details when attempting to close a claim."
  #   )
  # end
  #
  # defp validate_claim_resolution(changeset), do: changeset

  defp maybe_add_total_fuel_value(
         %Ecto.Changeset{changes: %{quantity_missing: quantity_missing, price_per_unit: price}} =
           changeset
       )
       when quantity_missing != "" or quantity_missing != 0 do
    changeset
    |> change(total_fuel_value: Decimal.mult(quantity_missing, price))
  end

  defp maybe_add_total_fuel_value(
         %Ecto.Changeset{
           changes: %{quantity_difference: quantity_difference, price_per_unit: price}
         } = changeset
       )
       when quantity_difference != "" or quantity_difference != 0 do
    changeset
    |> change(total_fuel_value: Decimal.mult(quantity_difference, price))
  end

  defp maybe_add_total_fuel_value(changeset), do: changeset

  # QUERIES

  def by_auction(auction_id, query \\ __MODULE__) do
    from(
      q in query,
      where: q.auction_id == ^auction_id
    )
  end
end
