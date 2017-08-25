defmodule Mix.Tasks.AnalyzeElixir do

  use Mix.Task

  @module_regex ~r/[A-Z](\w|\.(?:[A-Z]))+(?![:\w\{]|(?:.*\})|(?:.*do))/
  @module_name_regex ~r/defmodule\s*(\S+)\s*do/
  @ignored_regex ~r/#.*|"""[\s\S]*?"""|"[^\n]*?"|__[\s\S]*?__/

  @spec run(list())::nil
  def run(directory) do
    IO.inspect(directory)
    case directory do
        [] -> gather_from_dir(".")
        [dir|dirs] -> handle_many_dirs([dir|dirs])
#        [dir] -> gather_from_dir(dir)
    end
  end

  @spec gather_from_dir(binary()):: :ok|{:error, atom()}
  defp gather_from_dir(dir) do
    files = collect_file_names(dir <> "/**/*{ex, exs}")
    collected = collect_all_imports(files, [])
      |> Poison.encode!
    if dir == ".", do: dir = "all"
    File.write(dir <> ".json", collected, [:binary])
  end

  @spec handle_many_dirs(list())::nil
  defp handle_many_dirs(directories) do
    case directories do
        [h|t] -> gather_from_dir(h)
                 handle_many_dirs(t)
        _ -> nil 
    end
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
        splited_text = info 
          |> Map.keys
          |> Enum.join("|")
          |> Regex.compile
          |> elem(1)
          |> Regex.split(text)
        modules_info = Enum.zip(info |> Map.keys, splited_text)
        |> handle_many_modules_in_file(%{})
        Map.merge(info, modules_info)
      info |> Map.to_list |> length == 1 -> 
        [module_name] = info |> Map.keys
        get_module_mentions(text, module_name, info)
      true -> nil
    end
  end

  @spec handle_many_modules_in_file(list(), map())::map()
  defp handle_many_modules_in_file(modules, info) do
    case modules do
      [] -> info
      [{module_name, module_text}|modules] ->
        module_mentions = get_module_mentions(module_text, module_name, info)
        handle_many_modules_in_file(modules, Map.merge(module_mentions, info))
    end
  end

  @spec get_module_mentions(binary(), string(), map())::map()
  defp get_module_mentions(text, module_name, info) do
    text = Regex.replace(@ignored_regex, text, "")
    mentions = Regex.scan(@module_regex, text)
      |> extract_module_mentions([])
      |> Enum.uniq
    Map.put(info, module_name, mentions)
  end

  @spec extract_module_mentions(list(), list())::list()
  defp extract_module_mentions(mentions_list, acc) do
    case mentions_list do
      [] -> acc
      [h|t] -> extract_module_mentions(t, [Enum.at(h, 0) | acc])
    end
  end
  
  @spec collect_file_names(any())::any()
  defp collect_file_names(dir) do
    Path.wildcard(dir)
  end

  @spec read_file({string(), any()})::{binary(), any()}
  def read_file({file_path, info}) do
    {File.read(file_path) |> elem(1), info}
  end

  @spec get_all_modules_names({binary(), any()})::{binary(), map()}
  def get_all_modules_names({text, _info}) do
    module_names = extract_module_names(Regex.scan(@module_name_regex, text), [])
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

  @spec extract_module_names(list(), list())::list()
  defp extract_module_names(modules_list, acc) do
    case modules_list do
      [] -> acc |> List.flatten
      [[_|name]|t] -> extract_module_names(t, [name|acc])
    end
  end
end