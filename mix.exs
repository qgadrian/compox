defmodule Compox.MixProject do
  use Mix.Project

  @version "0.1.0-rc3"

  def project do
    [
      app: :compox,
      deps: deps(),
      description: description(),
      docs: [
        source_ref: "v#{@version}",
        main: "readme",
        extra_section: "README",
        formatters: ["html", "epub"],
        extras: extras()
      ],
      xref: [exclude: Postgrex.Protocol],
      elixir: "~> 1.9",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Compox.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:hackney, "~> 1.17"},
      {:jason, "~> 1.2"},
      {:tesla, "~> 1.7.0"},
      {:yaml_elixir, "~> 2.4"}
    ]
  end

  defp package do
    [
      name: "compox",
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Adrián Quintás"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/qgadrian/compox"}
    ]
  end

  defp description do
    "Start/stop your test environment using Docker containers"
  end

  defp extras do
    ["README.md"]
  end
end
