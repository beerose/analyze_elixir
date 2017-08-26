defmodule AnalyzeElixirTest do
  use ExUnit.Case
  require Mix.Tasks.AnalyzeElixir
  doctest AnalyzeElixir

  test "greets the world" do
    assert AnalyzeElixir.hello() == :world
  end
end
