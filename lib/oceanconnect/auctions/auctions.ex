defmodule Oceanconnect.Auctions do
  import Ecto.Query, warn: false
  alias Oceanconnect.Repo

  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBid,
    AuctionCache,
    AuctionComment,
    AuctionEvent,
    AuctionEventStore,
    AuctionEventStorage,
    AuctionFixture,
    AuctionStore,
    AuctionSuppliers,
    AuctionBarge,
    AuctionTimer,
    AuctionVesselFuel,
    Barge,
    Fuel,
    FuelIndex,
    Port,
    Solution,
    TermAuction,
    Vessel
  }

  alias Oceanconnect.Auctions.Command
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.{Company, User}
  alias Oceanconnect.Auctions.AuctionsSupervisor

  @term_types ["forward_fixed", "formula_related"]

  def is_term?(%{type: TermAuction}) do
    true
  end

  def is_term?(auction) do
    false
  end

  def submit_comment(
        auction,
        comment_params = %{},
        supplier_id,
        time_entered \\ DateTime.utc_now(),
        user \\ nil
      ) do
    comment =
      %{
        "supplier_id" => supplier_id,
        "time_entered" => time_entered
      }
      |> Map.merge(comment_params)
      |> AuctionComment.from_params_to_auction_comment(auction)

    comment
    |> Command.submit_comment(user)
    |> AuctionStore.process_command()

    case comment do
      %{comment: nil} -> {:invalid_comment, comment_params}
      _ -> {:ok, comment}
    end
  end

  def unsubmit_comment(
        %struct{id: auction_id},
        comment_id,
        supplier_id,
        user \\ nil
      )
      when is_auction(struct) do
    case comment_id do
      nil ->
        {:error, "Cannot delete comment"}

      _ ->
        %AuctionComment{
          id: comment_id,
          auction_id: auction_id,
          supplier_id: supplier_id,
          comment: ""
        }
        |> Command.unsubmit_comment(user)
        |> AuctionStore.process_command()

        :ok
    end
  end

  def bids_for_bid_ids(bid_ids, %state_struct{product_bids: product_bids})
      when is_auction_state(state_struct)
      when is_list(bid_ids) do
    product_bids
    |> Enum.map(fn {_product_id, product_bid_state} ->
      Enum.filter(product_bid_state.active_bids, fn bid ->
        bid.id in bid_ids
      end)
    end)
    |> List.flatten()
  end

  def place_bids(
        auction,
        bids_params = %{},
        supplier_id,
        time_entered \\ DateTime.utc_now(),
        user \\ nil
      ) do
    with :ok <- duration_time_remaining?(auction),
         {:ok, bids} <- make_bids(auction, bids_params, supplier_id, time_entered) do
      bids = Enum.map(bids, fn bid -> place_bid(bid, user) end)
      {:ok, bids}
    else
      {:error, :late_bid} -> {:error, :late_bid}
      {:invalid_bid, bid_params} -> {:invalid_bid, bid_params}
      error -> error
    end
  end

  def place_bid(bid, user \\ nil) do
    bid
    |> Command.process_new_bid(user)
    |> AuctionStore.process_command()

    bid
  end

  def make_bids(auction, bids_params, supplier_id, time_entered) do
    Enum.reduce_while(bids_params, {:ok, []}, fn {product_id, bid_params}, {:ok, acc} ->
      case make_bid(auction, product_id, bid_params, supplier_id, time_entered) do
        {:ok, bid} -> {:cont, {:ok, acc ++ [bid]}}
        invalid -> {:halt, invalid}
      end
    end)
  end

  def make_bid(auction, product_id, bid_params, supplier_id, time_entered \\ DateTime.utc_now()) do
    with bid_params <- maybe_add_amount(bid_params),
         bid_params <- maybe_add_min_amount(bid_params),
         bid_params <- convert_amounts(bid_params),
         true <- check_quarter_increments(bid_params) do
      bid =
        bid_params
        |> Map.put("supplier_id", supplier_id)
        |> Map.put("time_entered", time_entered)
        |> Map.put("vessel_fuel_id", product_id)
        |> AuctionBid.from_params_to_auction_bid(auction)

      case bid do
        %{amount: nil, min_amount: nil} -> {:invalid_bid, bid_params}
        _ -> {:ok, bid}
      end
    else
      _ -> {:invalid_bid, bid_params}
    end
  end

  def revoke_supplier_bids_for_product(auction, product_id, supplier_id, user \\ nil) do
    cond do
      duration_time_remaining?(auction) == :ok or
          decision_duration_time_remaining?(auction) == :ok ->
        auction
        |> Command.revoke_supplier_bids(product_id, supplier_id, user)
        |> AuctionStore.process_command()

        :ok

      true ->
        {:error, "error while revoking bid"}
    end
  end

  defp maybe_add_amount(params = %{"amount" => _}), do: params
  defp maybe_add_amount(params), do: Map.put(params, "amount", nil)

  defp maybe_add_min_amount(params = %{"min_amount" => _}), do: params
  defp maybe_add_min_amount(params), do: Map.put(params, "min_amount", nil)

  defp convert_amounts(bid_params = %{"amount" => amount, "min_amount" => min_amount}) do
    bid_params
    |> Map.put("amount", convert_currency_input(amount))
    |> Map.put("min_amount", convert_currency_input(min_amount))
  end

  defp convert_amounts(bid_params = %{"amount" => amount}) do
    bid_params
    |> Map.put("amount", convert_currency_input(amount))
  end

  defp convert_amounts(bid_params = %{"min_amount" => min_amount}) do
    bid_params
    |> Map.put("min_amount", convert_currency_input(min_amount))
  end

  defp convert_amounts(bid_params) do
    bid_params
  end

  defp convert_currency_input(""), do: nil
  defp convert_currency_input(amount) when is_number(amount), do: amount

  defp convert_currency_input(amount) do
    {float_amount, _} = Float.parse(amount)
    float_amount
  end

  defp check_quarter_increments(_params = %{"amount" => amount, "min_amount" => min_amount}) do
    check_quarter_increment(amount) && check_quarter_increment(min_amount)
  end

  defp check_quarter_increment(nil), do: true

  defp check_quarter_increment(amount) do
    amount / 0.25 - Float.floor(amount / 0.25) == 0.0
  end

  defp duration_time_remaining?(auction = %struct{id: auction_id}) when is_auction(struct) do
    case AuctionTimer.read_timer(auction_id, :duration) do
      false -> maybe_pending(get_auction_state!(auction))
      _ -> :ok
    end
  end

  defp decision_duration_time_remaining?(auction = %struct{id: auction_id})
       when is_auction(struct) do
    case AuctionTimer.read_timer(auction_id, :decision_duration) do
      false -> maybe_pending(get_auction_state!(auction))
      _ -> :ok
    end
  end

  defp maybe_pending(%{status: :pending}), do: :ok
  defp maybe_pending(%{status: :decision}), do: {:error, :late_bid}
  defp maybe_pending(_), do: :error

  def solution_selectable?(%User{is_admin: true}, _auction, _state), do: true

  def solution_selectable?(
        %User{company_id: buyer_id},
        %Auction{buyer_id: buyer_id},
        %{status: :decision} = _state
      ),
      do: true

  def solution_selectable?(
        %User{company_id: buyer_id},
        %TermAuction{buyer_id: buyer_id},
        %{status: status} = _state
      )
      when status in [:open, :decision],
      do: true

  def solution_selectable?(_, _, _), do: false

  # TODO: Migrate to only place `bids` on the Command, have Solution generated by AuctionStore.
  def select_winning_solution(
        bids,
        product_bids,
        auction,
        comment,
        port_agent,
        user \\ nil,
        closed_at \\ DateTime.utc_now()
      ) do
    solution = Solution.from_bids(bids, product_bids, auction)

    %Solution{solution | comment: comment}
    |> Command.select_winning_solution(auction, closed_at, port_agent, user)
    |> AuctionStore.process_command()
  end

  def is_participant?(auction = %struct{}, company_id) when is_auction(struct) do
    company_id in auction_participant_ids(auction)
  end

  def auction_participant_ids(auction = %struct{}) when is_auction(struct) do
    [auction.buyer_id | auction_supplier_ids(auction)]
  end

  def auction_supplier_ids(auction = %struct{}) when is_auction(struct) do
    auction_with_participants = with_participants(auction)
    Enum.map(auction_with_participants.suppliers, & &1.id)
  end

  def get_participant_name_and_ids_for_auction(auction_id) when is_integer(auction_id) do
    auction =
      auction_id
      |> get_auction!()
      |> fully_loaded()

    auction
    |> auction_participant_ids()
    |> Enum.map(&%{id: &1, name: AuctionSuppliers.get_name_or_alias(&1, auction)})
  end

  def list_auctions do
    regular_auctions =
      from(a in Auction, where: a.type == "spot")
      |> Repo.all()
      |> fully_loaded

    term_auctions =
      from(ta in TermAuction, where: ta.type in @term_types)
      |> Repo.all()
      |> fully_loaded

    regular_auctions ++ term_auctions
  end

  def list_participating_auctions(company_id) do
    (buyer_auctions(company_id) ++
       buyer_term_auctions(company_id) ++
       supplier_auctions(company_id) ++ supplier_term_auctions(company_id))
    |> Enum.uniq_by(& &1.id)
  end

  def list_upcoming_auctions(time_frame) do
    regular_auctions =
      Auction
      |> Auction.select_upcoming(time_frame)
      |> Repo.all()

    term_auctions =
      TermAuction
      |> TermAuction.select_upcoming(time_frame)
      |> Repo.all()

    regular_auctions ++ term_auctions
  end

  def upcoming_notification_sent?(%struct{id: auction_id}) when is_auction(struct) do
    Enum.any?(AuctionEventStore.event_list(auction_id), fn event ->
      event.type == :auction_upcoming_notified
    end)
  end

  defp buyer_auctions(buyer_id) do
    query =
      from(
        a in Auction,
        where: a.buyer_id == ^buyer_id and a.type == "spot",
        order_by: a.scheduled_start
      )

    query
    |> Repo.all()
    |> fully_loaded
  end

  defp buyer_term_auctions(buyer_id) do
    from(
      ta in TermAuction,
      where: ta.buyer_id == ^buyer_id and ta.type in @term_types,
      order_by: ta.scheduled_start
    )
    |> Repo.all()
    |> fully_loaded
  end

  defp supplier_auctions(supplier_id) do
    from(
      as in AuctionSuppliers,
      join: a in Auction,
      on: a.id == as.auction_id and a.type == "spot",
      where: as.supplier_id == ^supplier_id,
      where: not is_nil(a.scheduled_start),
      select: a,
      order_by: a.scheduled_start
    )
    |> Repo.all()
    |> fully_loaded
  end

  defp supplier_term_auctions(supplier_id) do
    from(
      as in AuctionSuppliers,
      join: ta in TermAuction,
      on: ta.id == as.term_auction_id and ta.type in @term_types,
      where: as.supplier_id == ^supplier_id,
      where: not is_nil(ta.scheduled_start),
      select: ta,
      order_by: ta.scheduled_start
    )
    |> Repo.all()
    |> fully_loaded
  end

  def get_auction(id) do
    with {:ok, auction} <- AuctionCache.read(id) do
      auction
    else
      _ ->
        if auction_type = get_auction_type(id) do
          Repo.get(auction_type, id)
          |> fully_loaded
        end
    end
  end

  def get_auction!(id) do
    with {:ok, auction} <- AuctionCache.read(id) do
      auction
    else
      _ ->
        get_auction_type!(id)
        |> Repo.get!(id)
        |> fully_loaded
    end
  end

  defp get_auction_type(auction_id) do
    try do
      get_auction_type!(auction_id)
    rescue
      Ecto.NoResultsError -> nil
    end
  end

  defp get_auction_type!(auction_id) do
    auction_type =
      from(a in Auction, select: a.type)
      |> Repo.get!(auction_id)

    case auction_type do
      "spot" -> Auction
      t when t in @term_types -> TermAuction
      _ -> nil
    end
  end

  def get_auction_state!(auction = %struct{}) when is_auction(struct) do
    case AuctionStore.get_current_state(auction) do
      {:error, "Auction Store Not Started"} ->
        AuctionEventStorage.most_recent_state(auction)

      state ->
        state
    end
  end

  def get_auction_status!(auction_id) when is_integer(auction_id) do
    with auction = %struct{} when is_auction(struct) <- get_auction!(auction_id),
         %{status: status} <- get_auction_state!(auction) do
      status
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def get_auction_status!(auction) do
    %{status: status} = get_auction_state!(auction)
    status
  end

  def get_auction_supplier(_auction_id, nil), do: nil
  def get_auction_supplier(nil, _supplier_id), do: nil

  def get_auction_supplier(auction = %Auction{id: nil}, supplier_id) do
    nil
  end

  def get_auction_supplier(auction = %TermAuction{id: nil}, supplier_id) do
    nil
  end

  def get_auction_supplier(%Auction{id: auction_id}, supplier_id) when not is_nil(auction_id) do
    Repo.get_by(AuctionSuppliers, %{auction_id: auction_id, supplier_id: supplier_id})
  end

  def get_auction_supplier(%TermAuction{id: term_auction_id}, supplier_id)
      when not is_nil(term_auction_id) do
    Repo.get_by(AuctionSuppliers, %{term_auction_id: term_auction_id, supplier_id: supplier_id})
  end

  def update_participation_for_supplier(%Auction{id: auction_id}, supplier_id, response)
      when response in ["yes", "no", "maybe"] do
    result =
      from(auction_supplier in AuctionSuppliers,
        where:
          auction_supplier.auction_id == ^auction_id and
            auction_supplier.supplier_id == ^supplier_id
      )
      |> Repo.update_all(set: [participation: response])

    auction = Repo.get(Auction, auction_id) |> fully_loaded()
    update_cache(auction)
    result
  end

  def update_participation_for_supplier(%TermAuction{id: term_auction_id}, supplier_id, response)
      when response in ["yes", "no", "maybe"] do
    result =
      from(auction_supplier in AuctionSuppliers,
        where:
          auction_supplier.term_auction_id == ^term_auction_id and
            auction_supplier.supplier_id == ^supplier_id
      )
      |> Repo.update_all(set: [participation: response])

    auction = Repo.get(TermAuction, term_auction_id) |> fully_loaded()
    update_cache(auction)
    result
  end

  def start_auction(auction = %struct{}, user \\ nil, started_at \\ DateTime.utc_now())
      when is_auction(struct) do
    auction
    |> Command.start_auction(started_at, user)
    |> AuctionStore.process_command()

    auction
  end

  def end_auction(auction = %struct{}, ended_at \\ DateTime.utc_now()) when is_auction(struct) do
    auction
    |> Command.end_auction(ended_at)
    |> AuctionStore.process_command()

    auction
  end

  def expire_auction(auction = %struct{}, expired_at \\ DateTime.utc_now())
      when is_auction(struct) do
    auction
    |> Command.end_auction_decision_period(expired_at)
    |> AuctionStore.process_command()

    auction
  end

  def cancel_auction(auction = %struct{}, user, canceled_at \\ DateTime.utc_now())
      when is_auction(struct) do
    auction
    |> Command.cancel_auction(canceled_at, user)
    |> AuctionStore.process_command()

    auction
  end

  def finalize_auction(_auction = %struct{id: auction_id}, state = %state_struct{})
      when is_auction(struct) and is_auction_state(state_struct) do
    with {:ok, _fixtures} <- create_fixtures_from_state(state),
         cached_auction = %struct{} when is_auction(struct) <- get_auction(auction_id),
         finalized_auction = %struct{} when is_auction(struct) <-
           persist_auction_from_cache(cached_auction) do
      {:ok, finalized_auction}
    else
      _ -> {:error, "Could not finalize auction details"}
    end
  end

  def persist_auction_from_cache(auction = %struct{id: auction_id}) when is_auction(struct) do
    attrs =
      Map.take(auction, [:auction_started, :auction_ended, :auction_closed_time, :port_agent])

    Repo.get(struct, auction_id)
    |> struct.changeset(attrs)
    |> Repo.update!()
  end

  def create_auction(attrs \\ %{}, user \\ nil)

  def create_auction(attrs = %{"scheduled_start" => start, "type" => type}, user)
      when start != "" and type in @term_types do
    with {:ok, auction} <-
           %TermAuction{} |> TermAuction.changeset_for_scheduled_auction(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  def create_auction(attrs = %{scheduled_start: start, type: type}, user)
      when start != "" and type in @term_types do
    with {:ok, auction} <-
           %TermAuction{} |> TermAuction.changeset_for_scheduled_auction(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  def create_auction(attrs = %{"type" => type}, user)
      when type in @term_types do
    with {:ok, auction} <- %TermAuction{} |> TermAuction.changeset(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  def create_auction(attrs = %{type: type}, user)
      when type in @term_types do
    with {:ok, auction} <- %TermAuction{} |> TermAuction.changeset(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  def create_auction(attrs = %{"scheduled_start" => start}, user) when start != "" do
    with {:ok, auction} <-
           %Auction{} |> Auction.changeset_for_scheduled_auction(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  def create_auction(attrs = %{scheduled_start: start}, user) when start != "" do
    with {:ok, auction} <-
           %Auction{} |> Auction.changeset_for_scheduled_auction(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  def create_auction(attrs, user) do
    with {:ok, auction} <- %Auction{} |> Auction.changeset(attrs) |> Repo.insert() do
      auction
      |> fully_loaded
      |> handle_auction_creation(user)
    else
      error -> error
    end
  end

  defp handle_auction_creation(auction, user) do
    user_on_record =
      case user do
        nil -> auction |> Repo.preload([:buyer]) |> Map.fetch!(:buyer)
        user -> user
      end

    auction
    |> create_supplier_aliases
    |> AuctionsSupervisor.start_child()

    {:ok, :command_accepted} =
      auction
      |> Command.create_auction(user_on_record)
      |> AuctionStore.process_command()

    {:ok, auction}
  end

  def update_cache(auction = %struct{}) when is_auction(struct) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()
  end

  def create_supplier_aliases(auction = %Auction{id: auction_id, suppliers: suppliers}) do
    :random.seed()

    Enum.reduce(Enum.shuffle(suppliers), 1, fn supplier, acc ->
      AuctionSuppliers
      |> Repo.get_by!(%{auction_id: auction_id, supplier_id: supplier.id})
      |> AuctionSuppliers.changeset(%{alias_name: "Supplier #{acc}"})
      |> Repo.update!()

      acc + 1
    end)

    auction
  end

  def create_supplier_aliases(auction = %TermAuction{suppliers: suppliers}) do
    :random.seed()

    Enum.reduce(Enum.shuffle(suppliers), 1, fn supplier, acc ->
      AuctionSuppliers
      |> Repo.get_by(%{term_auction_id: auction.id, supplier_id: supplier.id})
      |> AuctionSuppliers.changeset(%{alias_name: "Supplier #{acc}"})
      |> Repo.update!()

      acc + 1
    end)

    auction
  end

  def update_auction(
        %struct{scheduled_start: nil} = auction,
        %{"scheduled_start" => value} = attrs,
        user
      )
      when is_auction(struct) and (is_nil(value) or value == "") do
    auction
    |> struct.changeset(attrs)
    |> Repo.update()
    |> auction_update_command(user)
  end

  def update_auction(%struct{} = auction, attrs, user) when is_auction(struct) do
    auction
    |> struct.changeset_for_scheduled_auction(attrs)
    |> Repo.update()
    |> auction_update_command(user)
  end

  def update_auction!(
        %struct{scheduled_start: nil} = auction,
        %{"scheduled_start" => value} = attrs,
        user
      )
      when is_auction(struct) and (is_nil(value) or value == "") do
    auction
    |> struct.changeset(attrs)
    |> Repo.update!()
    |> auction_update_command(user)
  end

  def update_auction!(%struct{} = auction, attrs, user) when is_auction(struct) do
    auction
    |> struct.changeset_for_scheduled_auction(attrs)
    |> Repo.update!()
    |> auction_update_command(user)
  end

  def delete_auction(%struct{} = auction) when is_auction(struct) do
    Repo.delete(auction)
  end

  def change_auction(%struct{} = auction) when is_auction(struct) do
    struct.changeset(auction, %{})
  end

  def with_participants(%struct{} = auction) when is_auction(struct) do
    auction
    |> Repo.preload([:buyer, :suppliers])
  end

  def active_participants(auction_id) do
    AuctionEventStore.participants_from_events(auction_id)
    |> List.flatten()
  end

  def suppliers_with_alias_names(_auction = %struct{suppliers: nil}) when is_auction(struct),
    do: nil

  def suppliers_with_alias_names(auction = %struct{suppliers: suppliers})
      when is_auction(struct) do
    Enum.map(suppliers, fn supplier ->
      alias_name =
        case get_auction_supplier(auction, supplier.id) do
          %{alias_name: alias_name} -> alias_name
          _ -> nil
        end

      Map.put(supplier, :alias_name, alias_name)
    end)
  end

  def fully_loaded(term_auction = %TermAuction{}) do
    fully_loaded_auction =
      Repo.preload(term_auction, [
        :port,
        :vessels,
        :fuel,
        [fuel_index: [:fuel, :port]],
        :auction_suppliers,
        [buyer: :users],
        [suppliers: :users]
      ])

    fully_loaded_auction
    |> Map.put(:suppliers, suppliers_with_alias_names(fully_loaded_auction))
  end

  def fully_loaded(auction = %Auction{}) do
    fully_loaded_auction =
      Repo.preload(auction, [
        :port,
        :vessels,
        :fuels,
        :auction_suppliers,
        [auction_vessel_fuels: [:vessel, :fuel]],
        [buyer: :users],
        [suppliers: :users]
      ])

    fully_loaded_auction
    |> Map.put(:suppliers, suppliers_with_alias_names(fully_loaded_auction))
    |> Map.put(:vessels, Enum.uniq_by(fully_loaded_auction.vessels, & &1.id))
    |> Map.put(:fuels, Enum.uniq_by(fully_loaded_auction.fuels, & &1.id))
  end

  def fully_loaded(auctions) when is_list(auctions) do
    Enum.map(auctions, fn auction -> fully_loaded(auction) end)
  end

  def fully_loaded(company = %Company{}) do
    Repo.preload(company, [:users, :vessels, :ports])
  end

  def fully_loaded(port = %Port{}) do
    Repo.preload(port, [:companies])
  end

  def fully_loaded(vessel = %Vessel{}) do
    Repo.preload(vessel, [:company])
  end

  def fully_loaded(struct), do: struct

  def strip_non_loaded(struct = %{}) do
    Enum.reduce(maybe_convert_struct(struct), %{}, fn {k, v}, acc ->
      Map.put(acc, k, maybe_replace_non_loaded(v))
    end)
  end

  def strip_non_loaded(struct), do: struct

  defp auction_update_command({:ok, auction}, user) do
    auction
    |> fully_loaded
    |> Command.update_auction(user)
    |> AuctionStore.process_command()

    {:ok, auction}
  end

  defp auction_update_command({:error, changeset}, _user), do: {:error, changeset}

  defp auction_update_command(auction, user) do
    auction
    |> fully_loaded
    |> Command.update_auction(user)
    |> AuctionStore.process_command()

    auction
  end

  defp maybe_convert_struct(struct = %{__meta__: _meta}) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__, :inserted_at, :updated_at])
  end

  defp maybe_convert_struct(data), do: data

  defp maybe_replace_non_loaded(%Ecto.Association.NotLoaded{}), do: nil

  defp maybe_replace_non_loaded(value) when is_list(value) do
    Enum.map(value, fn list_item ->
      strip_non_loaded(list_item)
    end)
  end

  defp maybe_replace_non_loaded(value = %{__meta__: _meta}), do: strip_non_loaded(value)
  defp maybe_replace_non_loaded(value = %DateTime{}), do: value
  defp maybe_replace_non_loaded(value = %{}), do: strip_non_loaded(value)
  defp maybe_replace_non_loaded(value), do: value

  @doc """
  Returns the list of ports.

  ## Examples

      iex> list_ports()
      [%Port{}, ...]

  """
  def list_ports do
    Repo.all(Port)
  end

  def list_ports(params) do
    Port.alphabetical()
    |> Repo.paginate(params)
  end

  def list_active_ports do
    Port.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single port.

  Raises `Ecto.NoResultsError` if the Port does not exist.

  ## Examples

      iex> get_port!(123)
      %Port{}

      iex> get_port!(456)
      ** (Ecto.NoResultsError)

  """
  def get_port!(id), do: Repo.get!(Port, id)

  def get_active_port!(id) do
    Port.select_active()
    |> Repo.get!(id)
  end

  @doc """
  Creates a port.

  ## Examples

      iex> create_port(%{field: value})
      {:ok, %Port{}}

      iex> create_port(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_port(attrs = %{"companies" => company_ids}) do
    companies =
      Enum.map(company_ids, fn company_id ->
        Oceanconnect.Accounts.get_company!(String.to_integer(company_id))
      end)

    attrs =
      attrs
      |> Map.put("companies", companies)

    %Port{}
    |> Port.admin_changeset(attrs)
    |> Repo.insert()
  end

  def create_port(attrs) do
    %Port{}
    |> Port.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a port.

  ## Examples

      iex> update_port(port, %{field: new_value})
      {:ok, %Port{}}

      iex> update_port(port, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_port(
        %Port{} = port,
        attrs = %{"companies" => company_ids, "removed_companies" => removed_company_ids}
      ) do
    companies =
      Enum.map(company_ids, fn company_id ->
        Oceanconnect.Accounts.get_company!(String.to_integer(company_id))
      end)

    removed_companies =
      Enum.map(removed_company_ids, fn removed_company_id ->
        Oceanconnect.Accounts.get_company!(String.to_integer(removed_company_id))
      end)

    existing_companies = port.companies

    attrs =
      attrs
      |> Map.put("companies", companies ++ (existing_companies -- removed_companies))

    port
    |> Port.admin_changeset(attrs)
    |> Repo.update()
  end

  def update_port(%Port{} = port, attrs) do
    port
    |> Port.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Port.

  ## Examples

      iex> delete_port(port)
      {:ok, %Port{}}

      iex> delete_port(port)
      {:error, %Ecto.Changeset{}}

  """
  def delete_port(%Port{} = port) do
    Repo.delete(port)
  end

  def activate_port(port = %Port{}) do
    port
    |> Port.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_port(port = %Port{}) do
    port
    |> Port.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking port changes.

  ## Examples

      iex> change_port(port)
      %Ecto.Changeset{source: %Port{}}

  """
  def change_port(%Port{} = port) do
    Port.changeset(port, %{})
  end

  def port_with_companies(port = %Port{}) do
    port
    |> Repo.preload(:companies)
  end

  def ports_for_company(company = %Company{}) do
    company
    |> Repo.preload(ports: :companies)
    |> Map.get(:ports)
  end

  def companies_for_port(port = %Port{}) do
    from(c in Oceanconnect.Accounts.Company,
      join: p in assoc(c, :ports),
      where: p.id == ^port.id,
      select: c
    )
    |> Repo.all()
  end

  def supplier_list_for_port(%Port{id: id}) do
    id
    |> Port.suppliers_for_port_id()
    |> Repo.all()
  end

  def supplier_list_for_port(%Port{id: port_id}, buyer_id) do
    port_id
    |> Port.suppliers_for_port_id(buyer_id)
    |> Repo.all()
  end

  @doc """
  Returns list of vessels belonging to buyers company
  ## Examples
      iex> vessels_for_buyer(%Company{})
      [%Vessel{}, ...]

  """

  def vessels_for_buyer(%Company{id: id}) do
    Vessel.by_company(id)
    |> Vessel.select_active()
    |> Repo.all()
  end

  @doc """
  Returns the list of vessels.

  ## Examples

      iex> list_vessels()
      [%Vessel{}, ...]

  """
  def list_vessels do
    Repo.all(Vessel)
  end

  def list_vessels(params) do
    Vessel.alphabetical()
    |> Repo.paginate(params)
  end

  def list_active_vessels do
    Vessel.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single vessel.

  Raises `Ecto.NoResultsError` if the Vessel does not exist.

  ## Examples

      iex> get_vessel!(123)
      %Vessel{}

      iex> get_vessel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_vessel!(id), do: Repo.get!(Vessel, id) |> Repo.preload(:company)

  def get_active_vessel!(id) do
    Vessel.select_active()
    |> Repo.get!(id)
  end

  @doc """
  Creates a vessel.

  ## Examples

      iex> create_vessel(%{field: value})
      {:ok, %Vessel{}}

      iex> create_vessel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_vessel(attrs \\ %{}) do
    %Vessel{}
    |> Vessel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a vessel.

  ## Examples

      iex> update_vessel(vessel, %{field: new_value})
      {:ok, %Vessel{}}

      iex> update_vessel(vessel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_vessel(%Vessel{} = vessel, attrs) do
    vessel
    |> Vessel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Vessel.

  ## Examples

      iex> delete_vessel(vessel)
      {:ok, %Vessel{}}

      iex> delete_vessel(vessel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_vessel(%Vessel{} = vessel) do
    Repo.delete(vessel)
  end

  def activate_vessel(vessel = %Vessel{}) do
    vessel
    |> Vessel.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_vessel(vessel = %Vessel{}) do
    vessel
    |> Vessel.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vessel changes.

  ## Examples

      iex> change_vessel(vessel)
      %Ecto.Changeset{source: %Vessel{}}

  """
  def change_vessel(%Vessel{} = vessel) do
    Vessel.changeset(vessel, %{})
  end

  @doc """
  Returns the list of fuels.

  ## Examples

      iex> list_fuels()
      [%Fuel{}, ...]

  """

  def list_all_fuels do
    Fuel.alphabetical()
    |> Repo.all()
  end

  def list_fuels do
    Repo.all(Fuel)
  end

  def list_fuels(params) do
    Fuel.alphabetical()
    |> Repo.paginate(params)
  end

  def list_active_fuels do
    Fuel.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single fuel.

  Raises `Ecto.NoResultsError` if the Fuel does not exist.

  ## Examples

      iex> get_fuel!(123)
      %Fuel{}

      iex> get_fuel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_fuel!(id), do: Repo.get!(Fuel, id)

  def get_active_fuel!(id) do
    Fuel.select_active()
    |> Repo.get!(id)
  end

  @doc """
  Creates a fuel.

  ## Examples

      iex> create_fuel(%{field: value})
      {:ok, %Fuel{}}

      iex> create_fuel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_fuel(attrs \\ %{}) do
    %Fuel{}
    |> Fuel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a fuel.

  ## Examples

      iex> update_fuel(fuel, %{field: new_value})
      {:ok, %Fuel{}}

      iex> update_fuel(fuel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_fuel(%Fuel{} = fuel, attrs) do
    fuel
    |> Fuel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Fuel.

  ## Examples

      iex> delete_fuel(fuel)
      {:ok, %Fuel{}}

      iex> delete_fuel(fuel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_fuel(%Fuel{} = fuel) do
    Repo.delete(fuel)
  end

  def activate_fuel(fuel = %Fuel{}) do
    fuel
    |> Fuel.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_fuel(fuel = %Fuel{}) do
    fuel
    |> Fuel.changeset(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking fuel changes.

  ## Examples

      iex> change_fuel(fuel)
      %Ecto.Changeset{source: %Fuel{}}

  """
  def change_fuel(%Fuel{} = fuel) do
    Fuel.changeset(fuel, %{})
  end

  def list_barges, do: Repo.all(Barge)

  def list_barges(params) do
    Barge.alphabetical()
    |> Oceanconnect.Repo.paginate(params)
  end

  def list_active_barges do
    Barge.select_active()
    |> Barge.alphabetical()
    |> Repo.all()
  end

  def get_barge(id) do
    Repo.get(Barge, id)
  end

  def get_active_barge!(id) do
    Barge.select_active()
    |> Repo.get!(id)
  end

  def get_barge!(id) do
    Repo.get!(Barge, id)
  end

  def create_barge(attrs = %{"companies" => company_ids}) do
    companies =
      Enum.map(company_ids, fn company_id ->
        Accounts.get_company!(String.to_integer(company_id))
      end)

    attrs =
      attrs
      |> Map.put("companies", companies)

    %Barge{}
    |> Barge.admin_changeset(attrs)
    |> Repo.insert()
  end

  def create_barge(attrs) do
    %Barge{}
    |> Barge.changeset(attrs)
    |> Repo.insert()
  end

  def update_barge(
        %Barge{} = barge,
        attrs = %{"companies" => company_ids, "removed_companies" => removed_company_ids}
      ) do
    companies =
      Enum.map(company_ids, fn company_id ->
        Accounts.get_company!(String.to_integer(company_id))
      end)

    removed_companies =
      Enum.map(removed_company_ids, fn removed_company_id ->
        Oceanconnect.Accounts.get_company!(String.to_integer(removed_company_id))
      end)

    existing_companies = barge.companies

    attrs =
      attrs
      |> Map.put("companies", companies ++ (existing_companies -- removed_companies))

    barge
    |> Barge.admin_changeset(attrs)
    |> Repo.update()
  end

  def update_barge(%Barge{} = barge, attrs) do
    barge
    |> Barge.changeset(attrs)
    |> Repo.update()
  end

  def delete_barge(%Barge{} = barge) do
    Repo.delete(barge)
  end

  def activate_barge(barge = %Barge{}) do
    barge
    |> Barge.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_barge(barge = %Barge{}) do
    barge
    |> Barge.changeset(%{is_active: false})
    |> Repo.update()
  end

  def change_barge(%Barge{} = barge) do
    Barge.changeset(barge, %{})
  end

  def barge_with_companies(%Barge{} = barge) do
    barge
    |> Repo.preload(:companies)
  end

  def list_auction_barges(%struct{id: auction_id}) when is_auction(struct) do
    auction_id
    |> AuctionBarge.by_auction()
    |> Repo.all()
    |> Repo.preload(barge: [:port])
  end

  def approved_barges_for_winning_suppliers(winning_suppliers, %struct{} = auction)
      when is_auction(struct) do
    query =
      auction.id
      |> AuctionBarge.by_auction()

    query =
      "APPROVED"
      |> AuctionBarge.by_approval_status(query)

    queries =
      Enum.reduce(winning_suppliers, [], fn supplier, acc ->
        acc ++ [AuctionBarge.by_supplier(supplier.id, query)]
      end)

    Enum.flat_map(queries, fn query ->
      query
      |> Repo.all()
      |> Repo.preload(:barge)
    end)
  end

  def submit_barge(
        %struct{id: auction_id},
        barge = %Barge{id: barge_id},
        supplier_id,
        user \\ nil
      )
      when is_auction(struct) do
    {:ok, auction_barge} =
      %AuctionBarge{}
      |> AuctionBarge.changeset(%{
        auction_id: auction_id,
        barge_id: barge_id,
        supplier_id: supplier_id,
        approval_status: "PENDING"
      })
      |> Repo.insert()

    auction_barge
    |> Map.put(:barge, barge)
    |> Command.submit_barge(user)
    |> AuctionStore.process_command()
  end

  def unsubmit_barge(%struct{id: auction_id}, %Barge{id: barge_id}, supplier_id, user \\ nil)
      when is_auction(struct) do
    query =
      from(
        ab in AuctionBarge,
        where:
          ab.auction_id == ^auction_id and ab.supplier_id == ^supplier_id and
            ab.barge_id == ^barge_id
      )

    Repo.delete_all(query)

    %AuctionBarge{
      auction_id: auction_id,
      barge_id: barge_id,
      supplier_id: supplier_id
    }
    |> Command.unsubmit_barge(user)
    |> AuctionStore.process_command()
  end

  def approve_barge(%struct{id: auction_id}, %Barge{id: barge_id}, supplier_id, user \\ nil)
      when is_auction(struct) do
    query =
      from(
        ab in AuctionBarge,
        where:
          ab.auction_id == ^auction_id and ab.barge_id == ^barge_id and
            ab.supplier_id == ^supplier_id
      )

    Repo.update_all(query, set: [approval_status: "APPROVED"])

    auction_barges =
      query
      |> Repo.all()
      |> Repo.preload(barge: [:port])

    Enum.map(auction_barges, fn auction_barge ->
      auction_barge
      |> Command.approve_barge(user)
      |> AuctionStore.process_command()
    end)
  end

  def reject_barge(%struct{id: auction_id}, %Barge{id: barge_id}, supplier_id, user \\ nil)
      when is_auction(struct) do
    query =
      from(
        ab in AuctionBarge,
        where:
          ab.auction_id == ^auction_id and ab.barge_id == ^barge_id and
            ab.supplier_id == ^supplier_id
      )

    Repo.update_all(query, set: [approval_status: "REJECTED"])

    auction_barges =
      query
      |> Repo.all()
      |> Repo.preload(barge: [:port])

    Enum.map(auction_barges, fn auction_barge ->
      auction_barge
      |> Command.reject_barge(user)
      |> AuctionStore.process_command()
    end)
  end

  # Fixtures

  def get_fixture(fixture_id) do
    Repo.get(AuctionFixture, fixture_id)
    |> Repo.preload([:supplier, :vessel, :fuel])
  end

  def get_fixture!(fixture_id) do
    Repo.get!(AuctionFixture, fixture_id)
    |> Repo.preload([:supplier, :vessel, :fuel])
  end

  def fixtures_for_auction(auction = %struct{}) when is_auction(struct) do
    auction
    |> AuctionFixture.from_auction()
    |> Repo.all()
    |> Repo.preload([:supplier, :fuel, :vessel])
  end

  def fixtures_for_vessel_fuel(avf = %AuctionVesselFuel{}) do
    AuctionFixture.for_auction_vessel_fuel(avf)
    |> Repo.all()
  end

  def change_fixture(change = %AuctionFixture{}) do
    change
    |> AuctionFixture.update_changeset(%{})
  end

  def create_fixtures_from_state(
        _snapshot = %state_struct{
          winning_solution: %Solution{bids: bids}
        }
      )
      when is_auction_state(state_struct) do
    fixtures =
      bids
      |> Enum.map(&fixture_from_bid/1)

    {:ok, fixtures}
  end

  def create_fixtures_from_state(_state) do
    {:ok, []}
  end

  def create_fixture(auction_id, attrs \\ %{}) do
    attrs = Map.put(attrs, "auction_id", auction_id)

    %AuctionFixture{}
    |> AuctionFixture.update_changeset(attrs)
    |> Repo.insert()
  end

  def update_fixture(%AuctionFixture{} = fixture, attrs) do
    fixture
    |> AuctionFixture.update_changeset(attrs)
    |> Repo.update()
  end

  def fixture_from_bid(
        bid = %AuctionBid{
          vessel_fuel_id: avf_id,
          active: true
        }
      ) do
    case Repo.get(AuctionVesselFuel, avf_id) do
      vessel_fuel = %AuctionVesselFuel{} ->
        {:ok, fixture} =
          AuctionFixture.changeset_from_bid_and_vessel_fuel(bid, vessel_fuel)
          |> Repo.insert()

        fixture

      nil ->
        nil
    end
  end

  @doc """
  Returns the list of fuel_index_entries.

  ## Examples

      iex> list_fuel_index_entries()
      [%FuelIndex{}, ...]

  """
  def list_fuel_index_entries, do: Repo.all(FuelIndex)

  def list_fuel_index_entries(params) do
    FuelIndex.alphabetical()
    |> preload([:fuel, :port])
    |> Repo.paginate(params)
  end

  def list_fuel_index_entries_with_preloads,
    do: Repo.all(FuelIndex) |> Repo.preload([:fuel, :port])

  def list_active_fuel_index_entries do
    FuelIndex.select_active()
    |> Repo.all()
  end

  @doc """
  Gets a single fuel_index.

  Raises `Ecto.NoResultsError` if the Fuel index does not exist.

  ## Examples

      iex> get_fuel_index!(123)
      %FuelIndex{}

      iex> get_fuel_index!(456)
      ** (Ecto.NoResultsError)

  """
  def get_fuel_index!(id) do
    FuelIndex
    |> Repo.get!(id)
  end

  def get_active_fuel_index!(id) do
    FuelIndex.select_active()
    |> Repo.get!(id)
  end

  def fully_loaded_index(fuel_index = %FuelIndex{}) do
    fuel_index
    |> Repo.preload([:fuel, :port])
  end

  def fully_loaded_index(fuel_indexes) when is_list(fuel_indexes) do
    fuel_indexes
    |> Enum.map(&Repo.preload(&1, [:fuel, :port]))
  end

  @doc """
  Creates a fuel_index.

  ## Examples

      iex> create_fuel_index(%{field: value})
      {:ok, %FuelIndex{}}

      iex> create_fuel_index(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_fuel_index(attrs \\ %{}) do
    %FuelIndex{}
    |> FuelIndex.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a fuel_index.

  ## Examples

      iex> update_fuel_index(fuel_index, %{field: new_value})
      {:ok, %FuelIndex{}}

      iex> update_fuel_index(fuel_index, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_fuel_index(%FuelIndex{} = fuel_index, attrs) do
    fuel_index
    |> FuelIndex.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a FuelIndex.

  ## Examples

      iex> delete_fuel_index(fuel_index)
      {:ok, %FuelIndex{}}

      iex> delete_fuel_index(fuel_index)
      {:error, %Ecto.Changeset{}}

  """
  def delete_fuel_index(%FuelIndex{} = fuel_index) do
    Repo.delete(fuel_index)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking fuel_index changes.

  ## Examples

      iex> change_fuel_index(fuel_index)
      %Ecto.Changeset{source: %FuelIndex{}}

  """
  def change_fuel_index(%FuelIndex{} = fuel_index) do
    FuelIndex.changeset(fuel_index, %{})
  end

  def activate_fuel_index(fuel_index = %FuelIndex{}) do
    fuel_index
    |> FuelIndex.changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_fuel_index(fuel_index = %FuelIndex{}) do
    fuel_index
    |> FuelIndex.changeset(%{is_active: false})
    |> Repo.update()
  end
end
