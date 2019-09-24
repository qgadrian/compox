defmodule Compox.Docker.API.Containers do
  @moduledoc false

  require Logger

  @base_uri "/containers"

  @doc """
  Get the container id of the given container name.
  """
  @spec get_id(container_name :: String.t()) :: String.t()
  def get_id(container_name) when is_binary(container_name) do
    filters = %{name: [container_name]}

    "#{@base_uri}/json"
    |> Compox.Docker.API.Client.add_query_params(filters)
    |> Compox.Docker.API.Client.get!()
    |> decode_response()
    |> case do
      {:ok, containers} ->
        Enum.reduce_while(containers, "", fn
          %{"Id" => container_id} = container_found, _acc ->
            if match_partial_name(container_found, container_name) do
              {:halt, container_id}
            else
              {:cont, ""}
            end

          _container, _acc ->
            {:cont, ""}
        end)

      _ ->
        ""
    end
  end

  @doc """
  Inspect a container by ID.
  """
  @spec information(container_id :: String.t()) :: String.t()
  def information(container_id) do
    "#{@base_uri}/#{container_id}/json"
    |> Compox.Docker.API.Client.get!()
    |> decode_response()
  end

  @doc """
  Check if a container is running.
  """
  @spec running?(String.t()) :: boolean
  def running?(container_id) when is_binary(container_id) do
    container_id
    |> information()
    |> case do
      %{"State" => %{"Running" => true}} -> true
      _ -> false
    end
  end

  #
  # Private functions
  #

  @spec match_partial_name(container :: map, name :: String.t()) :: boolean()
  defp match_partial_name(container, name) do
    container
    |> Map.get("Names", [])
    |> Enum.any?(fn container_name ->
      container_name == name || container_name == "/#{name}"
    end)
  end

  @spec decode_response(response :: map) ::
          {:ok, map()} | {:error, String.t()}
  defp decode_response(%{status: 200, body: body}), do: {:ok, body}
  defp decode_response(%{status: 400}), do: {:error, "Bad parameter"}
  defp decode_response(%{status: 404}), do: {:error, "No such container"}
  # This is move temporally, received when no container and using an old API
  # version
  defp decode_response(%{status: 301}), do: {:error, "No such container"}
  defp decode_response(%{status: 500}), do: {:error, "Server error"}
  defp decode_response(%{status: code}), do: {:error, "Unknown code: #{code}"}
end
