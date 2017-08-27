defmodule AnalyzeElixirTest do
  use ExUnit.Case
  alias Mix.Tasks.AnalyzeElixir

  @one_module_in_file File.read("./test/one_module_in_file.txt") |> elem(1)
  @two_modules_in_file File.read("./test/two_modules_in_file.txt") |> elem(1)


  test "get all modules names" do
    assert AnalyzeElixir.get_all_modules_names({@two_modules_in_file, []}, {false, []}) |> elem(1)
           ==  %{"A" => [], "B" => []} 
  end

  test "get module mentions" do
    assert AnalyzeElixir.get_module_mentions(@one_module_in_file, "A", %{}) ==
            %{"A" => ["AnotherModule", "String"]}
  end

  test "get file modules mentions" do
    assert AnalyzeElixir.get_file_modules_mentions(
            {@two_modules_in_file, %{"A" => [], "B" => []}})
            == %{"A" => ["String"], "B" => ["C"]}
    assert AnalyzeElixir.get_file_modules_mentions(
            {@one_module_in_file, %{"A" => []}})
            == %{"A" => ["AnotherModule", "String"]}
  end

  test "make map from module names" do
    modules_list = ["A", "B"]
    assert AnalyzeElixir.make_map_from_modules_names(modules_list, %{}) ==
            %{"A" => [], "B" => []} 
  end  
end
