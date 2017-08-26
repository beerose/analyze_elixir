defmodule AnalyzeElixir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :analyze_elixir,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: "Tool to gather stats about module imports in project."
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Blackdahila"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/blackdahila/analyze_elixir"}
    ]
  end

  defp aliases do
    [c: "compile"]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
     {:recase, "~> 0.2"},
     {:poison, "~> 2.0"},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
