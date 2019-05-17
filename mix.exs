defmodule LavaPotion.MixProject do
  use Mix.Project

  def project do
    [
      app: :lavapotion,
      version: "1.0.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Abstract Lavalink Client for Elixir.",
      name: "lavapotion",
      source_url: "https://github.com/SamOphis/lavapotion",
      package: [
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/SamOphis/lavapotion"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LavaPotion, []}
    ]
  end

  defp deps do
    [
      {:jason , "~> 1.1"},
      {:mojito, "~> 0.3.0"},
      {:websockex, "~> 0.4.2"},
      {:gen_stage, "~> 0.14.1"}
    ]
  end
end
