defmodule Oceanconnect.FakeTaskSupervisor do
  def async_nolink(_, fun), do: fun.()
end
