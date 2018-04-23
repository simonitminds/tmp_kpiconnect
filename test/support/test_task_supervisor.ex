defmodule TestTaskSupervisor do
  def async_nolink(_, fun), do: fun.()
end
