defmodule Oceanconnect.Factory do
  use ExMachina.Ecto, repo: Oceanconnect.Repo

  def set_password(user) do
    hashed_password = Comeonin.Bcrypt.hashpwsalt(user.password)
    %{user | password_hash: hashed_password}
  end

  def company_factory() do
    %Oceanconnect.Accounts.Company{
      name: sequence(:name, &"Company-#{&1}")
    }
  end

  def user_factory() do
    %Oceanconnect.Accounts.User{
      email: sequence(:email, &("user-#{&1}@example.com")),
      password: "password",
      company: build(:company)
    }
    |> set_password
  end

  def auction_factory() do
    %Oceanconnect.Auctions.Auction{
       auction_start: DateTime.utc_now(),
       duration: 10 * 60_000,
       decision_duration: 15 * 60_000,
       fuel: build(:fuel),
       fuel_quantity: 1000,
       port: build(:port),
       vessel: build(:vessel),
       buyer: build(:user),
       suppliers: [build(:user)]
    }
  end

  def auction_without_suppliers_factory() do
    %Oceanconnect.Auctions.Auction{
       auction_start: DateTime.utc_now(),
       duration: 10 * 60_000,
       decision_duration: 15 * 60_000,
       fuel: build(:fuel),
       fuel_quantity: 1000,
       port: build(:port),
       vessel: build(:vessel),
       buyer: build(:user)
    }
  end

  def fuel_factory() do
    %Oceanconnect.Auctions.Fuel{
       name: "New Fuel"
    }
  end

  def port_factory() do
    %Oceanconnect.Auctions.Port{
       name: "New Port",
       country: "Timbuktu"
    }
  end

  def vessel_factory() do
    %Oceanconnect.Auctions.Vessel{
       imo: 1234567,
       name: sequence(:vessel_name, &"Vessel-#{&1}"),
       company: build(:company)
    }
  end
end
