defmodule Compox.Docker.Monitor do
  use ExUnit.Case

  alias Compox.Docker.Service
  alias Compox.Docker.Monitor
  alias Compox.DockerCompose

  describe "alive?/1" do
    test "returns true if the service is alive" do
      # DockerCompose.start()
      {:ok, service} = Monitor.get_by(:name, "hello-world")
      assert Monitor.alive?(service)
    end
  end
end
