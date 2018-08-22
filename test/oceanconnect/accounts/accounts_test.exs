defmodule Oceanconnect.AccountsTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Accounts

  describe "users" do
    alias Oceanconnect.Accounts.User

    @valid_attrs %{password: "some password"}
    @update_attrs %{email: "SOME EMAIL", password: "some updated password"}
    @invalid_attrs %{password: nil}

    setup do
      company = insert(:company)
      user = insert(:user, Map.merge(@valid_attrs, %{is_active: true, company: company}))
      inactive_user = insert(:user, Map.merge(@valid_attrs, %{is_active: false}))

      {:ok,
       %{
         user: Accounts.get_user!(user.id),
         inactive_user: Accounts.get_user!(inactive_user.id),
         company: company
       }}
    end

    test "list_users/0 returns all users", %{user: user, inactive_user: inactive_user} do
      assert Enum.map(Accounts.list_users(), fn f -> f.id end) == [user.id, inactive_user.id]
    end

    test "list_users/1 returns a paginated list of users", %{
      user: user,
      inactive_user: inactive_user
    } do
      page = Accounts.list_users(%{})
      assert page.entries == [user, inactive_user]
    end

    test "list_active_users/0 returns all users marked as active", %{
      user: user,
      inactive_user: inactive_user
    } do
      assert Enum.map(Accounts.list_active_users(), fn f -> f.id end) == [user.id]

      refute Enum.map(Accounts.list_active_users(), fn f -> f.id end) == [
               user.id,
               inactive_user.id
             ]
    end

    test "get_user!/1 returns the user with given id", %{user: user} do
      assert Accounts.get_user!(user.id) == user
    end

    test "get_active_user!/1 returns the active user with given id", %{
      user: user,
      inactive_user: inactive_user
    } do
      assert Accounts.get_active_user!(user.id) == user
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_active_user!(inactive_user.id) end
    end

    test "create_user/1 with valid data creates a user", %{company: company} do
      assert {:ok, %User{} = user} =
               Accounts.create_user(
                 Map.merge(@valid_attrs, %{email: "SOME EMAIL", company_id: company.id})
               )

      assert user.email == "SOME EMAIL"

      assert {:ok, %User{}} =
               Accounts.verify_login(%{"email" => user.email, "password" => @valid_attrs.password})
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user", %{user: user} do
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "SOME EMAIL"

      assert {:ok, %User{}} =
               Accounts.verify_login(%{
                 "email" => user.email,
                 "password" => @update_attrs.password
               })
    end

    test "update_user/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
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
      country: "some country"
    }
    @update_attrs %{
      address1: "some updated address",
      contact_name: "some updated contact_name",
      country: "some updated country",
      name: "some updated name"
    }
    @invalid_attrs %{address1: nil, contact_name: nil, country: nil, name: nil}

    setup do
      company = insert(:company, Map.merge(@valid_attrs, %{is_active: true}))
      inactive_company = insert(:company, Map.merge(@valid_attrs, %{is_active: false}))

      {:ok,
       %{
         company: Accounts.get_company!(company.id),
         inactive_company: Accounts.get_company!(inactive_company.id)
       }}
    end

    test "list_companies/0 returns all companies", %{
      company: company,
      inactive_company: inactive_company
    } do
      assert Enum.map(Accounts.list_companies(), fn f -> f.id end) == [
               company.id,
               inactive_company.id
             ]
    end

    test "list_companies/1 returns a paginated list all companies", %{
      company: company,
      inactive_company: inactive_company
    } do
      page = Accounts.list_companies(%{})
      assert page.entries == [company, inactive_company]
    end

    test "list_active_companies/0 returns all companys marked as active", %{
      company: company,
      inactive_company: inactive_company
    } do
      assert Enum.map(Accounts.list_active_companies(), fn f -> f.id end) == [company.id]

      refute Enum.map(Accounts.list_active_companies(), fn f -> f.id end) == [
               company.id,
               inactive_company.id
             ]
    end

    test "get_company!/1 returns the company with given id", %{
      company: company,
      inactive_company: inactive_company
    } do
      assert Accounts.get_company!(company.id) == company
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
               Accounts.create_company(Map.merge(@valid_attrs, %{name: "some name"}))

      assert all_values_match?(@valid_attrs, company)
    end

    test "create_company/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_company(@invalid_attrs)
    end

    test "update_company/2 with valid data updates the company", %{company: company} do
      assert {:ok, company} = Accounts.update_company(company, @update_attrs)
      assert %Company{} = company
      assert all_values_match?(@update_attrs, company)
    end

    test "update_company/2 with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_company(company, @invalid_attrs)
      assert company == Accounts.get_company!(company.id)
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

    test "list_company_barges/1 returns all barges associated with the company", %{
      company: company
    } do
      barges = [
        insert(:barge, companies: [company]),
        insert(:barge, companies: [company]),
        insert(:barge, companies: [company])
      ]

      assert Enum.map(barges, & &1.id) ==
               Enum.map(Accounts.list_company_barges(company.id), & &1.id)
    end
  end
end
