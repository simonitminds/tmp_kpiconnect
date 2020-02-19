defmodule OceanconnectWeb.Admin.SharedView do
  use OceanconnectWeb, :view

  def selection_list(item_list),
    do: [
      {nil, nil} | item_list |> Enum.map(&{&1.name, &1.id}) |> Enum.sort_by(&Kernel.elem(&1, 0))
    ]
end
