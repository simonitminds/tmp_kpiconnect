defmodule Oceanconnect.AccountsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Accounts

  describe "users" do
    alias Oceanconnect.Accounts.User

    @valid_attrs %{email: "some email", password: "some password"}
    @update_attrs %{email: "some updated email", password: "some updated password"}
    @invalid_attrs %{email: nil, password: nil}

    def user_fixture(attrs \\ @valid_attrs) do
      user = insert(:user, attrs)
      %{user | password: nil}
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert {:ok, %User{}} = Accounts.verify_login(
        %{"email" => user.email, "password" => @valid_attrs.password}
      )
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "some updated email"
      assert {:ok, %User{}} = Accounts.verify_login(
        %{"email" => user.email, "password" => @update_attrs.password}
      )
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "companies" do
    alias Oceanconnect.Accounts.Company

    @valid_attrs %{address1: "some address", contact_name: "some contact_name", country: "some country", name: "some name"}
    @update_attrs %{address1: "some updated address", contact_name: "some updated contact_name", country: "some updated country", name: "some updated name"}
    @invalid_attrs %{address1: nil, contact_name: nil, country: nil, name: nil}

    def company_fixture(attrs \\ %{}) do
      {:ok, company} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_company()

      company
    end

    test "list_companies/0 returns all companies" do
      company = company_fixture()
      assert Accounts.list_companies() == [company]
    end

    test "get_company!/1 returns the company with given id" do
      company = company_fixture()
      assert Accounts.get_company!(company.id) == company
    end

    test "create_company/1 with valid data creates a company" do
      assert {:ok, %Company{} = company} = Accounts.create_company(@valid_attrs)
      assert all_values_match?(@valid_attrs, company)
    end

    test "create_company/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_company(@invalid_attrs)
    end

    test "update_company/2 with valid data updates the company" do
      company = company_fixture()
      assert {:ok, company} = Accounts.update_company(company, @update_attrs)
      assert %Company{} = company
      assert all_values_match?(@update_attrs, company)
    end

    test "update_company/2 with invalid data returns error changeset" do
      company = company_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_company(company, @invalid_attrs)
      assert company == Accounts.get_company!(company.id)
    end

    test "delete_company/1 deletes the company" do
      company = company_fixture()
      assert {:ok, %Company{}} = Accounts.delete_company(company)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_company!(company.id) end
    end

    test "change_company/1 returns a company changeset" do
      company = company_fixture()
      assert %Ecto.Changeset{} = Accounts.change_company(company)
    end

    test "add_port_to_company/2 with valid data" do
      port = insert(:port)
      company = :company |> insert |> Accounts.add_port_to_company(port)
      assert company.ports == [port]
    end

    test "add_port_to_company/2 with existing ports" do
      [port1, port2] = insert_list(2, :port)
      company = :company |> insert |> Accounts.add_port_to_company(port1)
      |> Accounts.add_port_to_company(port2)
      assert Enum.all?(company.ports, fn(port) -> port in [port1, port2] end)
    end

    test "set_ports_on_company/2 with valid data" do
      ports = insert_list(2, :port)
      company = :company |> insert |> Accounts.set_ports_on_company(ports)
      assert company.ports == ports
    end

    test "set_ports_on_company/2 overwriting existing ports" do
      [port1, port2] = insert_list(2, :port)
      company = :company |> insert |> Accounts.set_ports_on_company([port1])
      |> Accounts.set_ports_on_company([port2])
      assert company.ports == [port2]
    end

  end
end
