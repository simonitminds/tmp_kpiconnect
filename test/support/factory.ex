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
      email: sequence(:email, &("USER-#{&1}@EXAMPLE.COM")),
      first_name: "test",
      last_name: "user",
      password: "password",
      company: build(:company)
    }
    |> set_password
  end

  def auction_factory() do
    start = DateTime.utc_now() |> DateTime.to_naive |> NaiveDateTime.add(20) |> DateTime.from_naive!("Etc/UTC")
    %Oceanconnect.Auctions.Auction{
      scheduled_start: start,
      duration: 10 * 60_000,
      decision_duration: 15 * 60_000,
      eta: DateTime.utc_now(),
      fuel: build(:fuel),
      fuel_quantity: 1000,
      port: build(:port),
      vessel: build(:vessel),
      buyer: build(:company),
      suppliers: [build(:company, is_supplier: true)]
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
