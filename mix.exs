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
          mode: (if Mix.env() == :prod, do: :release, else: :debug)
        ]
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.21.1"}
    ]
  end
end
