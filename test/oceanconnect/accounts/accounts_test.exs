defmodule Oceanconnect.AccountsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Accounts

  describe "users" do
    alias Oceanconnect.Accounts.User

    @valid_attrs %{email: "SOME EMAIL"}
    @update_attrs %{email: "SOME UPDATED EMAIL", password: "some updated password"}
    @invalid_attrs %{email: nil}

    setup do
      company = insert(:company)
      admin_company = insert(:company)
      observer_company = insert(:company)

      user = insert(:user, is_active: true, company: company)
      admin_user = insert(:user, is_admin: true, company: admin_company)
      inactive_user = insert(:user, is_active: false)
      observer_user = insert(:user, is_observer: true, company: observer_company)

      {:ok,
       %{
         admin_user: admin_user,
         admin_company_id: admin_company.id,
         observer_company_id: observer_company.id,
         user: user,
         inactive_user: inactive_user,
         observer_user: observer_user,
         company: company
       }}
    end

    test "list_users/0 returns all users", %{
      admin_user: admin_user,
      user: user,
      inactive_user: inactive_user,
      observer_user: observer_user
    } do
      assert Accounts.list_users() |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([user.id, admin_user.id, inactive_user.id, observer_user.id])
    end

    test "list_users/1 returns a paginated list of users", %{
      admin_user: admin_user,
      user: user,
      inactive_user: inactive_user,
      observer_user: observer_user
    } do
      page = Accounts.list_users(%{})

      assert page.entries |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([user.id, admin_user.id, inactive_user.id, observer_user.id])
    end

    test "list_observers/0 returns all observers", %{observer_user: observer_user} do
      assert Accounts.list_observers() |> Enum.map(& &1.id) |> Enum.sort() == [observer_user.id]
    end

    test "list_active_users/0 returns all users marked as active", %{
      admin_user: admin_user,
      user: user,
      observer_user: observer_user
    } do
      assert Accounts.list_active_users() |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([user.id, admin_user.id, observer_user.id])
    end

    test "list_admin_users/0 returns all admin users", %{admin_user: admin_user} do
      assert Accounts.list_admin_users() |> Enum.map(& &1.id) |> Enum.sort() == [admin_user.id]
    end

    test "is_admin?/1 returns true if admin", %{admin_company_id: admin_company_id} do
      assert Accounts.is_admin?(admin_company_id)
    end

    test "is_admin?/1 returns false if not admin", %{company: company} do
      refute Accounts.is_admin?(company.id)
    end

    test "is_admin?/1 returns false if nil provided" do
      refute Accounts.is_admin?(nil)
    end

    test "is_observer?/1 returns true if admin", %{observer_company_id: observer_company_id} do
      assert Accounts.is_observer?(observer_company_id)
    end

    test "is_observer?/1 returns false if not admin", %{company: company} do
      refute Accounts.is_observer?(company.id)
    end

    test "get_user!/1 returns the user with given id", %{user: user} do
      assert Accounts.get_user!(user.id).id == user.id
    end

    test "get_active_user!/1 returns the active user with given id", %{
      user: user,
      inactive_user: inactive_user
    } do
      assert Accounts.get_active_user!(user.id).id == user.id
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_active_user!(inactive_user.id) end
    end

    test "get_user_name!/1 returns the first and last name of the user", %{user: user} do
      assert Accounts.get_user_name!(user.id) == "#{user.first_name} #{user.last_name}"
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)

      assert user.email == "SOME EMAIL"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user", %{user: user} do
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "SOME UPDATED EMAIL"
    end

    test "update_user/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user.id == Accounts.get_user!(user.id).id
    end

    test "reset_password/2 with valid data updates the user's password", %{user: initial_user} do
      assert {:ok, user = ^initial_user} =
               Accounts.reset_password(initial_user, %{"password" => "password"})

      assert {:ok, _user} =
               Accounts.verify_login(%{"email" => user.email, "password" => "password"})
    end

    test "delete_user/1 deletes the user", %{user: user} do
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "activate_user/1 marks the user as active", %{inactive_user: inactive_user} do
      assert {:ok, %User{is_active: true}} = Accounts.activate_user(inactive_user)
    end

    test "deactivate_user/1 marks the user as inactive", %{user: user} do
      assert {:ok, %User{is_active: false}} = Accounts.deactivate_user(user)
    end

    test "change_user/1 returns a user changeset", %{user: user} do
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "companies" do
    alias Oceanconnect.Accounts.Company

    @valid_attrs %{
      address1: "some address",
      contact_name: "some contact_name",
      country: "some country",
      credit_margin_amount: 5.00
    }
    @update_attrs %{
      address1: "some updated address",
      contact_name: "some updated contact_name",
      country: "some updated country",
      name: "some updated name",
      credit_margin_amount: 0.00
    }
    @invalid_attrs %{address1: nil, contact_name: nil, country: nil, name: nil}

    setup do
      company = insert(:company, Map.merge(@valid_attrs, %{is_active: true}))
      broker_company = insert(:company, Map.merge(@valid_attrs, %{is_broker: true}))
      inactive_company = insert(:company, Map.merge(@valid_attrs, %{is_active: false}))

      {:ok,
       %{
         company: Accounts.get_company!(company.id),
         broker_company: Accounts.get_company!(broker_company.id),
         inactive_company: Accounts.get_company!(inactive_company.id)
       }}
    end

    test "list_companies/0 returns all companies", %{
      company: company,
      broker_company: broker_company,
      inactive_company: inactive_company
    } do
      assert Enum.map(Accounts.list_companies(), fn f -> f.id end) == [
               company.id,
               broker_company.id,
               inactive_company.id
             ]
    end

    test "list_companies/1 returns a paginated list all companies", %{
      company: company,
      broker_company: broker_company,
      inactive_company: inactive_company
    } do
      page = Accounts.list_companies(%{})
      assert page.entries == [company, broker_company, inactive_company]
    end

    test "list_broker_entities/0 returns all companies that are brokers", %{
      company: company,
      broker_company: broker_company
    } do
      assert Enum.map(Accounts.list_broker_entities(), fn f -> f.id end) == [
               broker_company.id
             ]

      refute Enum.any?(Accounts.list_broker_entities(), fn f -> f.id == company.id end)
    end

    test "list_active_companies/0 returns all companys marked as active", %{
      company: company,
      broker_company: broker_company,
      inactive_company: inactive_company
    } do
      assert Enum.map(Accounts.list_active_companies(), fn f -> f.id end) == [
               company.id,
               broker_company.id
             ]

      refute Enum.map(Accounts.list_active_companies(), fn f -> f.id end) == [
               company.id,
               broker_company.id,
               inactive_company.id
             ]
    end

    test "get_company!/1 returns the company with given id", %{
      company: company,
      broker_company: broker_company,
      inactive_company: inactive_company
    } do
      assert Accounts.get_company!(company.id) == company
      assert Accounts.get_company!(broker_company.id) == broker_company
      assert Accounts.get_company!(inactive_company.id) == inactive_company
    end

    test "get_active_company!/1 returns the active company with given id", %{
      company: company,
      inactive_company: inactive_company
    } do
      assert Accounts.get_active_company!(company.id) == company

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_active_company!(inactive_company.id)
      end
    end

    test "create_company/1 with valid data creates a company" do
      assert {:ok, %Company{} = company} =
               Accounts.create_company(
                 Map.merge(@valid_attrs, %{name: "some name", credit_margin_amount: 5.0})
               )

      assert all_values_match?(@valid_attrs, company)
    end

    test "create_company/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_company(@invalid_attrs)
    end

    test "create_company/1 with credit_margin_amount set to 0 creates a company with credit_margin_amount set to nil" do
      new_valid_attrs = Map.merge(@valid_attrs, %{name: "some name", credit_margin_amount: 0})
      assert {:ok, %Company{} = company} = Accounts.create_company(new_valid_attrs)

      refute all_values_match?(new_valid_attrs, company)
      assert company.credit_margin_amount == nil
    end

    test "update_company/2 with valid data updates the company", %{company: company} do
      new_update_attrs = Map.merge(@update_attrs, %{credit_margin_amount: 5.0})
      assert {:ok, company} = Accounts.update_company(company, new_update_attrs)
      assert %Company{} = company
      assert all_values_match?(new_update_attrs, company)
    end

    test "update_company/2 with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_company(company, @invalid_attrs)
      assert company == Accounts.get_company!(company.id)
    end

    test "update_company/2 with credit_margin_amount set to 0 updates a company with credit_margin_amount set to nil",
         %{company: company} do
      new_update_attrs = Map.merge(@update_attrs, %{credit_margin_amount: 0})
      assert {:ok, company} = Accounts.update_company(company, new_update_attrs)

      refute all_values_match?(new_update_attrs, company)
      assert company.credit_margin_amount == nil
    end

    test "delete_company/1 deletes the company", %{company: company} do
      assert {:ok, %Company{}} = Accounts.delete_company(company)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_company!(company.id) end
    end

    test "activate_company/1 marks the company as active", %{inactive_company: inactive_company} do
      assert {:ok, %Company{is_active: true}} = Accounts.activate_company(inactive_company)
    end

    test "deactivate_company/1 marks the company as inactive", %{company: company} do
      assert {:ok, %Company{is_active: false}} = Accounts.deactivate_company(company)
    end

    test "change_company/1 returns a company changeset", %{company: company} do
      assert %Ecto.Changeset{} = Accounts.change_company(company)
    end

    test "add_port_to_company/2 with valid data", %{company: company} do
      port = insert(:port)
      updated_company = company |> Accounts.add_port_to_company(port)
      assert updated_company.ports == [port]
    end

    test "add_port_to_company/2 with existing ports", %{company: company} do
      [port1, port2] = insert_list(2, :port)

      updated_company =
        company
        |> Accounts.add_port_to_company(port1)
        |> Accounts.add_port_to_company(port2)

      assert Enum.all?(updated_company.ports, fn port -> port in [port1, port2] end)
    end

    test "set_ports_on_company/2 with valid data", %{company: company} do
      ports = insert_list(2, :port)
      updated_company = company |> Accounts.set_ports_on_company(ports)
      assert updated_company.ports == ports
    end

    test "set_ports_on_company/2 overwriting existing ports", %{company: company} do
      [port1, port2] = insert_list(2, :port)

      updated_company =
        company
        |> Accounts.set_ports_on_company([port1])
        |> Accounts.set_ports_on_company([port2])

      assert updated_company.ports == [port2]
    end

    test "authorized_for_company? checks the presence of a user in a company", %{company: company} do
      company_user = insert(:user, company: company)
      assert Accounts.authorized_for_company?(company_user, company.id)
      refute Accounts.authorized_for_company?(company_user, nil)

      non_company_user = insert(:user)
      refute Accounts.authorized_for_company?(non_company_user, company.id)
      refute Accounts.authorized_for_company?(nil, company.id)
    end

    test "list_company_barges/1 returns all active barges associated with the company", %{
      company: company
    } do
      barges = [
        insert(:barge, companies: [company], is_active: true),
        insert(:barge, companies: [company], is_active: false),
        insert(:barge, companies: [company], is_active: true)
      ]

      [barge1, _barge2, barge3] = barges
      assert [barge1.id, barge3.id] == Enum.map(Accounts.list_company_barges(company.id), & &1.id)

      refute Enum.map(barges, & &1.id) ==
               Enum.map(Accounts.list_company_barges(company.id), & &1.id)
    end
  end
end
