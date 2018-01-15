defmodule Oceanconnect.Factory do
  use ExMachina.Ecto, repo: Oceanconnect.Repo

  def set_password(user) do
    hashed_password = Comeonin.Bcrypt.hashpwsalt(user.password)
    %{user | password_hash: hashed_password}
  end

  def user_factory() do
    %Oceanconnect.Accounts.User{
      email: "foo@example.com",
      password: "password"
    }
    |> set_password
  end

  def user_profile_factory() do
    %Oceanconnect.Accounts.UserProfile{
      user: build(:user),
      email: "shared@example.com"
    }
  end

  def new_datetime(offset_hours) do
    {:ok, datetime} = NaiveDateTime.new(2018, 1, 1, 0, 0, 0)
    datetime
    |> NaiveDateTime.add(offset_hours*3600, :second)
    |> DateTime.from_naive!("Etc/UTC")
  end

  def auction_factory() do
    %Oceanconnect.Auctions.Auction{
       auction_start: new_datetime(0),
       duration: 10,
       fuel: build(:fuel),
       fuel_quantity: 1000,
       port: build(:port),
       vessel: build(:vessel)
    }
  end

  def fuel_factory() do
    %Oceanconnect.Auctions.Fuel{
       name: "New Fuel"
    }
  end

  def port_factory() do
    %Oceanconnect.Auctions.Port{
       name: "New Port"
    }
  end

  def vessel_factory() do
    %Oceanconnect.Auctions.Vessel{
       imo: 1234567,
       name: "New Vessel"
    }
  end
end
