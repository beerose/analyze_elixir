defmodule FilesHelper do
  @spec collect_files_in_dir(any())::any()
  def collect_files_in_dir(dir) do
    Path.wildcard(dir  <> "/**/*{exs}") ++ Path.wildcard(dir <> "/**/*{ex}")
  end

  @spec read_file({string(), any()})::{binary(), any()}
  def read_file({file_path, info}) do
    {File.read(file_path) |> elem(1), info}
  end

  def write_to_file(collected, dir) do
    if dir == ".", do: dir = "all"
    File.write(dir <> ".json", collected, [:binary])
  end
end