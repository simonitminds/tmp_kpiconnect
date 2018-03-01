defmodule Oceanconnect.Auctions.PubSubTest do
  use Oceanconnect.DataCase

  test "Can subscribe to topics" do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:1")
  end

  test "Can receive messages to subscribed topics" do
    :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:1")
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:1", {:auction_started, [created_at: DateTime.utc_now()]})
    assert_received {:auction_started, [created_at: _]}
  end

  test "doesn't receive messages from a different topic" do
    :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:1")
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:2", {:auction_started, [created_at: DateTime.utc_now()]})
    refute_received {:auction_started, [created_at: _]}
  end

  test "entering bids" do

  end
end
