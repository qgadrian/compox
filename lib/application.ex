defmodule Compox.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    opts = Application.get_all_env(:compox)

    children = [{Compox, opts}]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Compox.Supervisor
    )
  end
end
