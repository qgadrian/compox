[![Hex version](https://img.shields.io/hexpm/v/sippet.svg "Hex version")](https://hex.pm/packages/compox)
[![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/compox)

# Compox

## Introduction

Compox ensure your whole infrastructure is up before running the tests.

Compox helps you to setup an ephemeral environment to run your tests using the
`docker-compose.yml` present in your project. After all your tests are done,
it will take the test environment down. This way your machine won't waste
resources having the containers running when they are not needed.

## Features

- Reuse created/running containers for other projects (e.g. shared database)
- Automatic start of the required container services
- Automatic stop of the required container services

## Installation

Adding `compox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:compox, "~> 0.1.0-rc3", only: [:test]}
  ]
end
```

## Usage

To use Compox follow these steps:

- Create a `docker-compose.yml` file with the containers that will be started
  by this application.

- Ensure Compox starts all containers before running the tests:

```elixir
defp aliases do
  [
    test: ["compox.up", "ecto.create --quiet", "ecto.migrate --quiet", "test"]
  ]
end
```

- Edit your `test_helper.exs` to stop the containers after the tests are
  done:

```elixir
ExUnit.after_suite(fn _ ->
  Compox.stop()
end)
```

### Upchecks

Sometimes a container is started by it takes a while to be ready to be used by
your application. For example, a database container can be started by the
database will take few seconds to start accepting connections.

To avoid any errors, Compox supports _upchecks_ probe configurations to validate
whether a container can be used or not.

You can implement your own logic to validate if a container is ready (see
example below) or use the default provided upchecks:

* `Postgres`: `Compox.Upchecks.Postgrex`

### Example

Compox allows you to configure a project to start/stop the containers to run the
tests, but also provides configuration to **work with any kind of situation**.

For example, some of or coworkers prefer to have the containers running all the
time. In this case you want to ensure the docker containers are started before the test, so people that prefer to save resources will start the containers, but you will also won't to avoid to take containers down.

You `config/test.exs` file will look like:

```elixir
use Mix.Config

config :compox,
  auto_start: true,
  auto_stop: false,
  exclude: ["a_service_should_not_be_started"],
  container_upchecks: [
    "postgres-service": {Compox.Upchecks.Postgrex, []},
    another_service: fn ->
      Another.Connection.up?()
    end
  ]
```

The people who will want to stop the containers after test can use a [_dotenv_
library](https://github.com/BlakeWilliams/envy) to change the `auto_stop` config to `true` on their machines.

> This can work the other way around, start/stopping the containers always and
> having `dotfile` config to skipping the start/stop.
