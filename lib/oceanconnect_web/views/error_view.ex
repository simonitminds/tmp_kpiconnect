defmodule OceanconnectWeb.ErrorView do
  use OceanconnectWeb, :view

  # def render("500.html", _assigns) do
  #   "Internal server error"
  # end

  # def render("422.json", _assigns) do
  #   "Unspecified Error"
  # end

  # def render("401.json", _assigns) do
  #   "Unauthorized"
  # end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end
end
