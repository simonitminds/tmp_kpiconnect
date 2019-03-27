defmodule Oceanconnect.Notifications.DelayedNotificationsSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor
  require Logger
  alias Oceanconnect.Notifications.DelayedNotifications

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(notification_name) do
    with {:ok, notification_pid} <-
           DynamicSupervisor.start_child(
             __MODULE__,
             {Oceanconnect.Notifications.DelayedNotifications, notification_name}
           ) do
      IO.inspect(notification_name, label: "OKAY ------------>")
      {:ok, {notification_pid}}
    else
      {:error, {:already_started, pid}} ->
        {:error, {:already_started, pid}}

      error ->
        Logger.error(inspect(error))
        raise("Could Not Start Delayed Notification Process for: #{notification_name}")
    end
  end

  def stop_child(notification_name) do
    with {:ok, pid} <-
           Oceanconnect.Notifications.DelayedNotifications.find_pid(notification_name),
         :ok <- DynamicSupervisor.terminate_child(__MODULE__, pid) do
      Logger.info("Delayed Notification: #{notification_name} Services Stopped")
      {:ok, "Delayed Notification: #{notification_name} Services Stopped"}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
