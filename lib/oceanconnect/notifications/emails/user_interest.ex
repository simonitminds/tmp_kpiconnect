defmodule Oceanconnect.Notifications.Emails.UserInterest do
  use Oceanconnect.Notifications.Email

  def generate(new_user_info), do: emails(new_user_info)

  defp emails(new_user_info) do
    user_interest_email()
    |> subject("An unregistered user is requesting more information")
    |> render(
      "user_interest.html",
      new_user_info: new_user_info
    )
    |> List.wrap()
  end
end
