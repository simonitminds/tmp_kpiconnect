defmodule OceanconnectWeb.LayoutView do
  use OceanconnectWeb, :view

  def root_class_list do
    list =
      if Application.get_env(:oceanconnect, :disable_css_transitions) do
        "qa-disable-transitions"
      else
        ""
      end

    list
  end
end
