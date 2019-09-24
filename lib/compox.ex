defmodule Compox do
  @moduledoc """
  Module to work with a Docker environment for testing.

  Compox starts Docker containers when the application starts (see
  [configuration](#configuration) for more info).

  ## Containers availability

  Compox makes two checks to ensure the containers are available:

  * the container has `running` status.
  * the exposed ports to the host, if any, accept connections.

  ## Configuration

  * `auto_start`: Whether the docker compose services should start with this
  application. Defaults to `true`.

  * `auto_stop`: Whether the docker compose services should stop after the tests.
  Defaults to `true`.

  * `exclude`: The list of Docker services to exclude. These services won't be
  started by Compox.

  * `container_upchecks`: Keyword list of functions that will be used to check
  if a container an _up_ state. See `Compox.Docker.Containers` documentation for
  more info.

  * `kill_on_finish`: Kills the containers instead of stopping them.

  ### Container upchecks

  There are containers that need more checks rather than just accepting
  connection on a port. In those cases, you can use `container_upchecks` config
  and provide a function that will be reevaluated until it returns `:ok`.

  #### Example: checking Postgres connection

  If you use a PostgreSQL containers, you will need to ensure that ecto will be
  able to connect to the container before running the tests. In the following
  example, we will be using `Postgrex.Protocol.connect/1` to attempt a
  connection to the database. The _upcheck function_ will check whether the
  Postgres connection returned an application (invalid credentials, unknown
    catalog...) or a connection error.
  """

  use GenServer

  require Logger

  alias Compox.Docker.Compose
  alias Compox.Docker.Services

  @doc false
  def start_link(opts) when is_list(opts) do
    Mix.shell().info("[compox] Starting containers...")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stops all the started containers.

  Any container started using the `docker-compose.yml` will be stopped.
  """
  @spec stop() :: :ok
  def stop() do
    if Application.get_env(:compox, :auto_stop, true) do
      Mix.shell().info("[compox] Stopping containers...")
      GenServer.call(__MODULE__, :stop, 20000)
    end
  end

  @doc false
  @impl GenServer
  def init(opts) do
    if Keyword.get(opts, :auto_start, true) do
      services = Compose.up(opts)

      Mix.shell().info("[compox] All containers up!")

      {:ok, %{services: services}}
    else
      {:ok, %{services: []}}
    end
  end

  @doc false
  @impl GenServer
  def handle_call(:stop, _from, %{services: services}) do
    Services.stop(services)

    Mix.shell().info("[compox] All containers gone!")

    {:reply, :ok, nil}
  end

  @doc false
  @impl GenServer
  def handle_info(_message, state) do
    {:noreply, state}
  end
end
