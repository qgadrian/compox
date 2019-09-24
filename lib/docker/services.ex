defmodule Compox.Docker.Services do
  @moduledoc """
  Provides functions to work with [Compox
  services](`Compox.Docker.Services.Service`).
  """

  require Logger

  alias Compox.Docker.Services.Service
  alias Compox.Docker.API.Containers
  alias Compox.Docker.ConnectionCheck

  @doc """
  Starts [services](`t:Compox.Docker.Service.t/0`) from the `docker compose`.

  Each service is started independently.

  After all services are launch, returns the list of services updated with each
  container id.
  """
  @spec start([Service.t()]) :: [Service.t()]
  def start(services) when is_list(services) do
    Enum.map(services, &start/1)
  end

  @spec start(Service.t()) :: Service.t()
  def start(%Service{name: name} = service) do
    Mix.shell().info("[compox] Starting service #{name}...")

    System.cmd("docker-compose", ["up", "-d", name])

    container_id = Containers.get_id(name)

    ConnectionCheck.wait_until_up(container_id)
    ConnectionCheck.maybe_do_upcheck(name)

    %{service | container_id: container_id}
  end

  @doc """
  Stops the given [services](`t:Compox.Docker.Service.t/0`).

  In order to stop the containers, sends a `SIGKILL` message to all the
  container process.
  """
  @spec stop([Service.t()]) :: :ok
  def stop(services) when is_list(services) do
    Enum.each(services, &stop/1)
  end

  @spec stop(Service.t()) :: :ok
  def stop(%Service{name: name, container_id: container_id}) do
    stop_or_kill =
      :compox
      |> Application.get_env(:kill_on_finish, false)
      |> case do
        true -> "kill"
        false -> "stop"
      end

    # XXX: give some time to ecto processes to finish. 1 of 100 times there
    # are connections and error logs are thrown
    Process.sleep(200)

    System.cmd("docker-compose", [stop_or_kill, name])

    ConnectionCheck.wait_until_down(container_id)

    Mix.shell().info("[compox] Service #{name} killed")
  end
end
