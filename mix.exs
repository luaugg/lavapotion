defmodule LavaPotion.MixProject do
  use Mix.Project

  def project do
    [
      app: :lavapotion,
      version: "0.5.0",
      elixir: "~> 1.7",
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
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.13.0"},
      {:websockex, "~> 0.4.0"}
    ]
  end
end
