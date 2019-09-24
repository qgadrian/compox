defmodule Compox.Docker.Compose do
  @moduledoc """
  Module that provides functions to interact with Docker and `docker-compose`
  files.
  """

  require Logger

  alias Compox.Docker.Services.Service
  alias Compox.Docker.Compose.Parser
  alias Compox.Docker.Services

  @doc """
  Start services listed on the `docker-compose.yml` file.
  """
  @spec up(keyword) :: list(Service.t())
  def up(opts \\ []) do
    with {:ok, services} <- Parser.parse("docker-compose.yml"),
         excluded_services <- Keyword.get(opts, :exclude, []),
         filtered_services <- filter_services(services, excluded_services) do
      Services.start(filtered_services)
    else
      {:error, reason} ->
        Mix.shell().error(
          "[compox] Error Docker containers: #{inspect(reason)}"
        )

        []
    end
  end

  #
  # Private functions
  #

  @spec filter_services(
          services :: list(Service.t()),
          excluded_services :: list(String.t())
        ) :: list(Service.t())
  defp filter_services(services, excluded_services) do
    Enum.reject(services, &(&1.name in excluded_services))
  end
end
