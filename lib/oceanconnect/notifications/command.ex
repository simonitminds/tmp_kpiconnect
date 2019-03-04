defmodule Oceanconnect.Notifications.Command do
  alias __MODULE__
  defstruct auction_id: nil,
    command: nil,
    notification_name: nil,
    data: nil

  def schedule_notification(name, send_time, emails) do
    %Command{command: :schedule_notification, notification_name: name, data: %{send_time: send_time, emails: emails}}
  end

  def reschedule_notification(name, send_time, emails) do
    %Command{command: :reschedule_notification, notification_name: name, data: %{send_time: send_time, emails: emails}}
  end

  def cancel_notification(name) do
    %Command{command: :cancel_notification, notification_name: name, data: %{}}
  end
end
