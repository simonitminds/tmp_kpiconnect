defmodule Oceanconnect.Admin.Fixture.EditPage do
  use Oceanconnect.Page

  def delete_fixture do
    find_element(:css, ".qa-admin-delete")
    |> click

    Hound.Helpers.Dialog.accept_dialog()
  end
end
