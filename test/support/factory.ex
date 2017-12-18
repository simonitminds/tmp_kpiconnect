defmodule Oceanconnect.Factory do
  use ExMachina.Ecto, repo: Oceanconnect.Repo

  def port_factory() do
    %Oceanconnect.Auctions.Port{
       name: "New Port"
    }
  end
end
