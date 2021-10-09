defmodule Compox.Docker.API.Containers do
  @moduledoc false

  require Logger

  @base_uri "/containers"

  @opaque container_id :: String.t()

  @doc """
  Get the container id of the given container name.
  """
  @spec get_id(container_name :: String.t()) :: String.t() | nil
  def get_id(container_name) when is_binary(container_name) do
    filters = %{
      filters: %{
        name: [container_name],
        status: ["created", "running", "paused", "exited"]
      }
    }

    "#{@base_uri}/json"
    |> Compox.Docker.API.Client.add_query_params(filters)
    |> Compox.Docker.API.Client.get()
    |> case do
      {:ok, %Tesla.Env{body: containers}} ->
        Enum.reduce_while(containers, nil, fn
          %{"Id" => container_id} = container_found, _acc ->
            if match_partial_name(container_found, container_name) do
              {:halt, container_id}
            else
              {:cont, nil}
            end

          _container, _acc ->
            {:cont, nil}
        end)

      _ ->
        nil
    end
  end

  @spec start(container_id()) :: :ok | {:error, term}
  def start(container_id) do
    "#{@base_uri}/#{container_id}/start"
    |> Compox.Docker.API.Client.post!(%{})
    |> decode_response()
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @spec stop(container_id()) :: :ok | {:error, term}
  def stop(container_id) do
    "#{@base_uri}/#{container_id}/stop"
    |> Compox.Docker.API.Client.post!(%{})
  end

  @spec kill(container_id()) :: :ok | {:error, term}
  def kill(container_id) do
    "#{@base_uri}/#{container_id}/kill"
    |> Compox.Docker.API.Client.post!(%{})
  end

  @doc """
  Inspect a container by ID.
  """
  @spec information(container_id :: String.t()) ::
          {:ok, String.t() | map()} | {:error, String.t()}
  def information(container_id) do
    "#{@base_uri}/#{container_id}/json"
    |> Compox.Docker.API.Client.get!()
    |> decode_response()
  end

  @doc """
  Check if a container is running.
  """
  @spec running?(String.t() | nil) :: boolean
  def running?(container_id) when is_binary(container_id) do
    container_id
    |> information()
    |> case do
      {:ok, %{"State" => %{"Running" => true}}} -> true
      _ -> false
    end
  end

  def running?(nil), do: false

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
  defp decode_response(%{status: 204}), do: {:ok, "No error"}
  defp decode_response(%{status: 301}), do: {:error, "No such container"}
  defp decode_response(%{status: 304}), do: {:ok, "Already started"}
  defp decode_response(%{status: 400}), do: {:error, "Bad parameter"}
  defp decode_response(%{status: 404}), do: {:error, "No such container"}
  # This is move temporally, received when no container and using an old API
  # version
  defp decode_response(%{status: 500}), do: {:error, "Server error"}
  defp decode_response(%{status: code}), do: {:error, "Unknown code: #{code}"}
end
