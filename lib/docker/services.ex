defmodule Compox.Docker.Services do
  @moduledoc """
  Provides functions to work with [Compox
  services](`Compox.Docker.Services.Service`).
  """

  require Logger

  alias Compox.Docker.Services.Service
  alias Compox.Docker.API.Containers
  alias Compox.Docker.Upcheck

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
  def start(%Service{name: service_name} = service) do
    service =
      case Containers.get_id(service_name) do
        nil ->
          container_id = start_container(service_name)

          %{service | container_id: container_id}

        container_id ->
          Mix.shell().info(
            "[compox] Found a container for #{service_name}, reusing it"
          )

          reuse_container(container_id)

          %{service | container_id: container_id, reused: true}
      end

    Upcheck.maybe_do_upcheck(service_name)

    service
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
  def stop(%Service{
        name: service_name,
        container_id: container_id,
        reused: reused
      }) do
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

    case {reused, stop_or_kill} do
      {true, "kill"} ->
        Containers.kill(container_id)

      {true, "stop"} ->
        Containers.stop(container_id)

      {false, _} ->
        System.cmd("docker-compose", [stop_or_kill, service_name])
    end

    Upcheck.wait_until_down(container_id)

    Mix.shell().info("[compox] Service #{service_name} killed")
  end

  #
  # Private functions
  #

  @spec reuse_container(Containers.container_id()) :: Containers.container_id()
  defp reuse_container(container_id) do
    case Containers.start(container_id) do
      :ok ->
        container_id

      {:error, reason} ->
        Mix.shell().error("[compox] Error trying to reuse container: #{reason}")

        container_id
    end
  end

  # If there container id
  @spec start_container(service_name :: String.t()) :: Containers.container_id()
  defp start_container(service_name) do
    Mix.shell().info("[compox] Starting service #{service_name}...")

    System.cmd("docker-compose", ["up", "--no-deps", "-d", service_name])

    container_id = Containers.get_id(service_name)

    Upcheck.wait_until_up(container_id)

    container_id
  end
end
