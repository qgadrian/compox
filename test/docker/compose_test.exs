defmodule Compox.Docker.ComposeTest do
  use ExUnit.Case

  alias Compox.Docker.Compose
  alias Compox.Docker.Service

  describe "start/1" do
    test "starts a docker compose file" do
      services_to_start = [
        %Service{
          image: "mendhak/http-https-echo",
          name: "hello-world"
        }
      ]

      services = Docker.Compose.start(services_to_start)

      refute Enum.any?(services, &is_nil(&1.port))

      Process.sleep(5000)

      assert :ok = Docker.Compose.stop(services)
    end
  end
end
