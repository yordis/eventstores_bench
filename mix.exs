defmodule EventstoresBench.MixProject do
  use Mix.Project

  def project do
    [
      app: :eventstores_bench,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventstore, "1.4.7"},
      {:spear, "1.4.1"},
      {:benchee, "1.3.1"},
      {:testcontainers, "1.11.8"},
      {:benchee_html, "1.0.1"}
    ]
  end
end
