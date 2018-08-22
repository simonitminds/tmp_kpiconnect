defmodule Mix.Tasks.FixData do
  use Mix.Task

  @shortdoc "foo"
  def run("master") do
    Mix.shell().info("master")
  end

  def run(_) do
    Mix.shell().info("branch")
  end
end
