defmodule Compox.Docker.Compose.Parser do
  @moduledoc false

  alias Compox.Docker.Services.Service

  @typedoc """
  Path to the `docker-compose.yml` file.
  """
  @type docker_compose_path :: String.t()

  @doc """
  Parses a `docker compose` file and returns the list of
  [services](`t:Compox.Docker.Service.t/0`).

  See [Docker compose
  specification](https://github.com/compose-spec/compose-spec/blob/master/spec.md)
  for more information.
  """
  @spec parse(docker_compose_path) :: {:ok, [Service.t()]} | {:error, term}
  def parse(docker_compose_path) do
    with {:ok, file} <- File.read(docker_compose_path),
         {:ok, yaml} <- YamlElixir.read_from_string(file) do
      {:ok, get_services(yaml)}
    else
      error -> error
    end
  end

  #
  # Private functions
  #

  @spec get_services(map) :: [Service.t()]
  defp get_services(%{"services" => services}) do
    Enum.map(services, &get_service/1)
  end

  defp get_services(_), do: []

  @spec get_service(map) :: Service.t() | {:error, term}
  defp get_service({service_name, %{"image" => image} = service_attrs}) do
    attrs =
      service_attrs
      |> get_base_attrs()
      |> Map.merge(%{
        name: service_name,
        image: image
      })

    struct(Service, attrs)
  end

  # TODO get the container name, it needs to be used to get the id
  defp get_service({service_name, %{"build" => build_path} = service_attrs}) do
    attrs =
      service_attrs
      |> get_base_attrs()
      |> Map.merge(%{
        name: service_name,
        image: build_path
      })

    struct(Service, attrs)
  end

  defp get_service(service),
    do: {:error, "Unknown service configuration: #{inspect(service)}"}

  @spec get_base_attrs(service_attrs :: map) :: map
  defp get_base_attrs(service_attrs) do
    service_attrs
    |> Map.take(["container_name"])
    |> Enum.map(fn
      {k, v} -> {String.to_atom(k), v}
    end)
    |> Enum.into(%{})
  end
end
