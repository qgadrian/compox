defmodule Compox.Docker.ComposeTest do
  use ExUnit.Case

  alias Compox.Docker.Compose
  alias Compox.Docker.Services
  alias Compox.Docker.Services.Service

  describe "start/1" do
    test "starts a docker compose file" do
      services_to_start = [
        %Service{
          image: "mendhak/http-https-echo",
          name: "hello-world"
        }
      ]

      services = Compose.up(services_to_start)

      assert :ok = Services.stop(services)
    end
  end
end
