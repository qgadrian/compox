defmodule Compox.Docker.Upcheck do
  @moduledoc false

  # XXX: use back off?
  @default_sleep 500

  @doc """
  Waits the current process and checks the given service until the container is
  up.

  This function receives a _service name_ and uses the `container_upchecks`
  config to ensure the container meets the requirements to be consider
  available.
  """
  @spec maybe_do_upcheck(service_name :: String.t()) :: :ok
  def maybe_do_upcheck(service_name) do
    :compox
    |> Application.get_env(:container_upchecks, [])
    |> Keyword.get(String.to_atom(service_name))
    |> case do
      nil -> :ok
      upcheck_fun -> do_upcheck(upcheck_fun, service_name)
    end
  end

  @doc """
  Waits the current process un the container is running.
  """
  @spec wait_until_up(container_id :: String.t()) :: :ok
  def wait_until_up(container_id) do
    container_id
    |> Compox.Docker.API.Containers.running?()
    |> case do
      true ->
        Process.sleep(@default_sleep)
        wait_until_up(container_id)

      _ ->
        :ok
    end
  end

  @doc """
  Waits the current process un the container is not running.
  """
  @spec wait_until_down(container_id :: String.t()) :: :ok
  def wait_until_down(container_id) do
    container_id
    |> Compox.Docker.API.Containers.running?()
    |> case do
      true ->
        Process.sleep(500)
        wait_until_down(container_id)

      _ ->
        :ok
    end
  end

  #
  # Private functions
  #

  @spec do_upcheck(
          {upcheck_module :: module(), args :: list(any)},
          service_name :: String.t()
        ) ::
          :ok
  defp do_upcheck({upcheck_module, args} = upcheck, service_name)
       when is_atom(upcheck_module) and is_list(args) do
    upcheck_module
    |> Kernel.apply(:upcheck, [args])
    |> case do
      :ok ->
        :ok

      _error ->
        Mix.shell().info("[compox] waiting for #{service_name}...")
        Process.sleep(@default_sleep)
        do_upcheck(upcheck, service_name)
    end
  end

  @spec do_upcheck(upcheck_fun :: function(), service_name :: String.t()) :: :ok
  defp do_upcheck(upcheck_fun, service_name) do
    case upcheck_fun.() do
      :ok ->
        :ok

      _error ->
        Mix.shell().info("[compox] waiting for #{service_name}...")
        Process.sleep(@default_sleep)
        do_upcheck(upcheck_fun, service_name)
    end
  end
end
