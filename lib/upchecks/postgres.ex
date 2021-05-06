defmodule Compox.Upchecks.Postgrex do
  @moduledoc """
  Module that provides the upcheck implementation to ensure a Postgres
  connection can be used.

  This module tries to connect to a Postgres database, and it will succeed if
  the connection can be established and a credentials error is returned.

  ## Configuration

  `#{__MODULE__}` supports the following args:

    * `hostname`: The hostname to check the connection. Defaults to `localhost`.

  ```elixir
  config :compox,
    container_upchecks: [
      "postgres": {Compox.Upchecks.Postgrex, []}
    ]
  ```
  """

  @behaviour Compox.Upcheck

  @impl true
  def upcheck(opts \\ []) do
    hostname = Keyword.get(opts, :hostname, "localhost")

    Postgrex.Protocol.connect(
      hostname: hostname,
      database: "",
      username: "",
      types: nil
    )
    |> case do
      {:error, %{postgres: _}} -> :ok
      _ -> :error
    end
  rescue
    _error -> :error
  end
end
