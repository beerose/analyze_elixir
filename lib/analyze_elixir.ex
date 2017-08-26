defmodule Mix.Tasks.AnalyzeElixir do

  use Mix.Task

  @module_regex ~r/[A-Z](\w|\.(?:[A-Z]))+(?![:\w\{]|(?:.*\})|(?:.*do))/
  @module_name_regex ~r/defmodule\s*(\S+)\s*do/
  @ignored_regex ~r/#.*|"""[\s\S]*?"""|"[^\n]*?"|__[\s\S]*?__/

  @spec run(list())::nil
  def run(directory) do
    case directory do
        [] -> gather_from_dir(".")
        dirs -> Enum.reduce(dirs, 0,  fn(d, _) -> gather_from_dir(d) end)
    end
  end

  @spec gather_from_dir(binary()):: :ok|{:error, atom()}
  defp gather_from_dir(dir) do
    files = collect_files_in_dir(dir <> "/**/*{exs}") ++ collect_files_in_dir(dir <> "/**/*{ex}")
    collected = collect_all_imports(files, [])
      |> Poison.encode!
    if dir == ".", do: dir = "all"
    File.write(dir <> ".json", collected, [:binary])
  end

  @spec collect_all_imports(list(), list())::list()
  def collect_all_imports(files, acc) do
    case files do
      [] -> acc
      [h|t] -> 
        info =
        {h, %{}}
        |> read_file()
        |> get_all_modules_names # have text and map with module names 
        |> get_file_modules_mentions
        collect_all_imports(t, [info|acc])        
    end
  end 

  @spec get_file_modules_mentions({binary(), map()})::map()
  def get_file_modules_mentions({text, info}) do
    cond do
      info |> Map.to_list |> length > 1 -> 
        [_|splited_text] = info 
          |> Map.keys
          |> Enum.join("|")
          |> Regex.compile
          |> elem(1)
          |> Regex.split(text)
        modules_info = Enum.zip(info |> Map.keys, splited_text)
        |> Enum.reduce(%{}, fn({name, text}, acc) -> 
            Map.merge(acc, get_module_mentions(text, name, info), 
              fn(_k, v1, v2) -> if v1 == [] 
                do v2 else v1 end
              end)
            end)
        Map.merge(info, modules_info)
      info |> Map.to_list |> length == 1 -> 
        [module_name] = info |> Map.keys
        get_module_mentions(text, module_name, info)
      true -> nil
    end
  end

  @spec get_module_mentions(binary(), string(), map())::map()
  defp get_module_mentions(text, module_name, info) do
    text = Regex.replace(@ignored_regex, text, "")
    mentions = Regex.scan(@module_regex, text)
      |> Enum.reduce([], fn(m, acc) -> [Enum.at(m, 0) | acc] end)  
      |> Enum.uniq
    Map.put(info, module_name, mentions)
  end

  @spec collect_files_in_dir(any())::any()
  defp collect_files_in_dir(dir) do
    Path.wildcard(dir)
  end

  @spec read_file({string(), any()})::{binary(), any()}
  def read_file({file_path, info}) do
    {File.read(file_path) |> elem(1), info}
  end

  @spec get_all_modules_names({binary(), any()})::{binary(), map()}
  def get_all_modules_names({text, _info}) do
    module_names = Regex.scan(@module_name_regex, text)
      |> Enum.reduce([], fn(m, acc) -> [Enum.at(m, 1) | acc] end)
    {text, make_map_from_modules_names(module_names, %{})}
  end

  @spec make_map_from_modules_names(list(), map())::map()
  defp make_map_from_modules_names(modules_list, acc) do
    case modules_list do
      [] -> acc
      [h|t] -> make_map_from_modules_names(t,
                Map.put(acc, h, []))
    end
  end

  def get_all_modules_in_project() do
    Regex.scan(~r/app:\s:(\w+)/, File.read("./mix.exs") |> elem(1))
    |> Enum.at(0) |> Enum.at(1) |> String.to_atom
    |> :application.get_key(:modules)
  end
end