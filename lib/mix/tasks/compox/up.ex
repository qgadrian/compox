defmodule Mix.Tasks.Compox.Up do
  use Mix.Task

  def run(_) do
    Application.ensure_all_started(:compox)
  end
end
