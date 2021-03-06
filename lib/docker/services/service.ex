defmodule Compox.Docker.Services.Service do
  @moduledoc """
  Represents a [Docker service](https://docs.docker.com/get-started/part3/).
  """

  @typedoc """
  A internal representation of a Docker service present in a `docker-compose`
  file:

  * `name`: The name of the Docker service.
  * `image`: The Docker image used by the service.
  * `container_id`: The `id` of the Docker container.
  * `container_name`: The name of the service container, defaults to `nil`.
  * `reused`: Whether the container running this service was already created or
  running.
  """
  @type t :: %__MODULE__{
          container_id: String.t(),
          container_name: String.t(),
          image: String.t(),
          name: String.t(),
          reused: boolean
        }

  @enforce_keys [:name]
  defstruct [
    :container_id,
    :image,
    :name,
    reused: false,
    container_name: nil
  ]
end
