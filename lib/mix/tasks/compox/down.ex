defmodule Mix.Tasks.Compox.Down do
  use Mix.Task

  def run(_) do
    Compox.stop()
  end
end
