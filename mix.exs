defmodule TableTopEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :table_top_ex,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: [
        table_top_ex: [
          mode: if(Mix.env() == :prod, do: :release, else: :debug)
        ]
      ],
      deps: deps(),

      # Docs
      name: "TableTopEx",
      source_url: "https://github.com/FlyingDutchmanGames/table_top_ex",
      homepage_url: "https://github.com/FlyingDutchmanGames/table_top_ex",
      docs: [
        # The main page in the docs
        main: "TableTopEx",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.21.1"},
      {:typed_struct, "~> 0.2.1"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end
end
