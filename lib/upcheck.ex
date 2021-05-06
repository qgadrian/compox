defmodule Compox.Upcheck do
  @moduledoc """
  Module that provides callback definitions to run containers upchecks.
  """

  @callback upcheck(args :: list(any)) :: :ok | :error
end
