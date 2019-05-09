defmodule Oceanconnect.Deliveries.QuantityClaim do
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

  @derive {Poison.Encoder, except: [:__meta__, :auction, :buyer, :notice_recipient, :fixture, :responses]}
  schema "claims" do
    field(:type, :string)
    field(:closed, :boolean, default: false)
    field(:quantity_missing, :integer)
    field(:price_per_unit, :float)
    field(:total_fuel_value, :float)
    field(:response, :string, virtual: true)
    field(:additional_information, :string)
    field(:notice_recipient_type, :string)
    field(:supplier_last_correspondence, :utc_datetime_usec)
    field(:admin_last_correspondence, :utc_datetime_usec)

    has_many(:responses, ClaimResponse)

    belongs_to(:supplier, Company)
    belongs_to(:buyer, Company)
    belongs_to(:notice_recipient, Company)

    belongs_to(:receiving_vessel, Vessel)
    belongs_to(:delivered_fuel, Fuel)
    belongs_to(:delivering_barge, Barge)

    belongs_to(:fixture, AuctionFixture)
    belongs_to(:auction, Auction)

    timestamps()
  end

  @required_fields [
    :type,
    :quantity_missing,
    :price_per_unit,
    :total_fuel_value,
    :receiving_vessel_id,
    :delivered_fuel_id,
    :delivering_barge_id,
    :notice_recipient_id,
    :notice_recipient_type,
    :buyer_id,
    :supplier_id,
    :fixture_id
  ]

  def changeset(%__MODULE__{} = claim, attrs) do
    claim
    |> cast(attrs, @required_fields ++ [:closed, :response, :auction_id, :additional_information])
    |> maybe_add_fixture()
    |> maybe_add_notice_recipient()
    |> maybe_add_last_correspondence()
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:receiving_vessel_id)
    |> foreign_key_constraint(:delivered_fuel_id)
    |> foreign_key_constraint(:delivering_barge_id)
    |> foreign_key_constraint(:notice_recipient_id)
    |> foreign_key_constraint(:buyer_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fixture_id)
  end

  defp maybe_add_fixture(
         %Ecto.Changeset{
           changes: %{
             supplier_id: supplier_id,
             delivered_fuel_id: fuel_id,
             receiving_vessel_id: vessel_id
           }
         } = changeset
       ) do
    case get_field(changeset, :auction_id) || get_field(changeset, :term_auction_id) do
      nil ->
        changeset

      auction_id ->
        fixtures =
          Auctions.get_auction!(auction_id)
          |> Auctions.fixtures_for_auction()

        [fixture | _] =
          Enum.filter(fixtures, fn fixture ->
            fixture.vessel_id == vessel_id and fixture.fuel_id == fuel_id and
              fixture.supplier_id == supplier_id
          end)

        changeset
        |> change(fixture_id: fixture.id)
    end
  end

  defp maybe_add_fixture(changeset), do: changeset

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

  def by_auction(auction_id, query \\ __MODULE__) do
    from(
      q in query,
      where: q.auction_id == ^auction_id
    )
  end
end
