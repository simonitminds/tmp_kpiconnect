defmodule Oceanconnect.AuctionSuppliersTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionSuppliers}

  describe "get_name_or_alias/2" do
    setup do
      auction = insert(:auction)

      anon_auction =
        :auction
        |> insert(anonymous_bidding: true)
        |> Auctions.create_supplier_aliases()
        |> Auctions.fully_loaded()

      {:ok, %{auction: auction, anon_auction: anon_auction}}
    end

    test "provides name for buyer on non anon_auction", %{
      auction: %Auction{buyer: buyer} = auction
    } do
      assert AuctionSuppliers.get_name_or_alias(buyer.id, auction) == buyer.name
    end

    test "provides name for buyer on anon_auction", %{
      anon_auction: %Auction{buyer: buyer} = anon_auction
    } do
      assert AuctionSuppliers.get_name_or_alias(buyer.id, anon_auction) == buyer.name
    end

    test "provides name for non anon_auction", %{
      auction: %Auction{suppliers: [supplier | _]} = auction
    } do
      assert AuctionSuppliers.get_name_or_alias(supplier.id, auction) == supplier.name
    end

    test "provides alias_name for anon_auction", %{
      anon_auction: %Auction{suppliers: [supplier | _]} = anon_auction
    } do
      refute AuctionSuppliers.get_name_or_alias(supplier.id, anon_auction) == supplier.name
    end

    test "provides name for non anon_payload", %{auction: %Auction{suppliers: [supplier | _]}} do
      assert AuctionSuppliers.get_name_or_alias(supplier.id, %{}) == supplier.name
    end

    test "provides alias_name for anon_payload", %{
      anon_auction: %Auction{id: auction_id, suppliers: [supplier | _]}
    } do
      refute AuctionSuppliers.get_name_or_alias(supplier.id, %{
               anonymous_bidding: true,
               auction_id: auction_id
             }) == supplier.name
    end

    test "provides buyer name for anon_payload", %{anon_auction: %Auction{buyer: buyer}} do
      assert AuctionSuppliers.get_name_or_alias(buyer.id, %{
               anonymous_bidding: true,
               buyer_id: buyer.id
             }) == buyer.name
    end
  end
end
