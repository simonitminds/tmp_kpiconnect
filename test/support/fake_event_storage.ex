defmodule Oceanconnect.FakeEventStorage do
  def events_by_auction(_id) do
    []
  end

  def persist(event) do
    #no-op
    {:ok, event}
  end
end
