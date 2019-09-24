defmodule Compox.Docker.API.Client do
  @moduledoc false

  use Tesla

  @docker_host Application.compile_env(
                 :compox,
                 :docker_host,
                 "http+unix://%2fvar%2frun%2fdocker.sock"
               )
  @docker_version Application.compile_env(:compox, :docker_version, "v1.27")

  plug(Tesla.Middleware.BaseUrl, "#{@docker_host}/#{@docker_version}")
  plug Tesla.Middleware.JSON

  adapter(Tesla.Adapter.Hackney, recv_timeout: 30_000)

  @doc """
  Converts the given params hash and add it to the url.
  """
  @spec add_query_params(url :: String.t(), params :: keyword) :: String.t()
  def add_query_params(url, params) do
    filtered_query =
      params
      |> Enum.map(fn {p, v} -> {p, Jason.encode!(v)} end)
      |> URI.encode_query()

    "#{url}?#{filtered_query}"
  end
end
