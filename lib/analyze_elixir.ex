defmodule Mix.Tasks.AnalyzeElixir do

  use Mix.Task

  @module_regex ~r/[A-Z](\w|\.(?:[A-Z]))+(?![:\w\{]|(?:.*\})|(?:.*do))|[A-Z]/
  @module_name_regex ~r/defmodule\s*(\S+)\s*do/
  @ignored_regex ~r/#.*|"""[\s\S]*?"""|"[^\n]*?"|__[\s\S]*?__/

  @spec run(list())::nil
  def run(directory) do
    local = {Enum.member?(directory, "-only_local"), get_all_modules_in_project()}
    case directory do
        [] -> gather_from_dir(".", local)
        dirs -> Enum.reduce(dirs, 0,  fn(d, _) -> gather_from_dir(d, local) end)
    end
  end

  @spec gather_from_dir(binary(), boolean()):: :ok|{:error, atom()}
  defp gather_from_dir(dir, local) do
    files = collect_files_in_dir(dir <> "/**/*{exs}") ++ collect_files_in_dir(dir <> "/**/*{ex}")
    collected = collect_all_imports(files, %{}, local) |>
               Poison.encode!
    if dir == ".", do: dir = "all"
    File.write(dir <> ".json", collected, [:binary])
  end

  @spec collect_all_imports(list(), list(), {boolean(), list()})::list()
  def collect_all_imports(files, acc, local) do
    case files do
      [] -> acc
      [path|t] -> 
        info =
        {path, %{}}
        |> read_file()
        |> get_all_modules_names(local) # have text and map with module names 
        |> get_file_modules_mentions(path)
        collect_all_imports(t, Map.merge(info, acc), local) 
    end
  end 

  @spec get_file_modules_mentions({binary(), map()}, string())::map()
  def get_file_modules_mentions({text, info}, path) do
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
            Map.merge(acc, %{name => get_module_mentions(text, name, info[name], path)}, 
              fn(_k, v1, v2) -> if v1["mentions"]== [] 
                do v2 else v1 end
              end)
            end)
        Map.merge(info, modules_info)
      info |> Map.to_list |> length == 1 -> 
        [module_name] = info |> Map.keys
        %{module_name => get_module_mentions(text, module_name, info[module_name], path)}
      true -> nil
    end
  end

  @spec get_module_mentions(binary(), string(), map(), string())::map()
  def get_module_mentions(text, module_name, info, path) do
    text = Regex.replace(@ignored_regex, text, "")
    mentions = Regex.scan(@module_regex, text)
      |> Enum.reduce([], fn(m, acc) -> [Enum.at(m, 0) | acc] end)  
      |> Enum.uniq 
      |> Enum.filter(fn(x) -> x != module_name end)
    Map.put(info, "mentions", mentions)
    |> Map.put("path", path)
  end

  @spec collect_files_in_dir(any())::any()
  defp collect_files_in_dir(dir) do
    Path.wildcard(dir)
  end

  @spec read_file({string(), any()})::{binary(), any()}
  def read_file({file_path, info}) do
    {File.read(file_path) |> elem(1), info}
  end

  @spec get_all_modules_names({binary(), any()}, {boolean(), list()})::{binary(), map()}
  def get_all_modules_names({text, _info}, local) do
    module_names = Regex.scan(@module_name_regex, text)
      |> Enum.reduce([], fn(m, acc) -> [Enum.at(m, 1) | acc] end)
    case local do
      {true, local_modules} -> module_names = 
        Enum.filter(module_names, 
        fn(mod) -> Enum.member?(local_modules, mod) end)
      _ -> nil
    end
    {text, make_map_from_modules_names(module_names, %{})}
  end

  @spec make_map_from_modules_names(list(), map())::map()
  def make_map_from_modules_names(modules_list, acc) do
    case modules_list do
      [] -> acc
      [h|t] -> make_map_from_modules_names(t,
                Map.put(acc, h, %{"mentions" => [], "statements" => [], "path" => ''}))
    end
  end

  def get_all_modules_in_project() do
    app_name = Regex.scan(~r/app:\s:(\w+)/, File.read("./mix.exs") |> elem(1))
    |> Enum.at(0) |> Enum.at(1) |> String.to_atom
    Mix.shell.cmd """
    mix run -e 'IO.inspect(:application.get_key(:#{app_name}, :modules) |> elem(1))' > "modules.txt"
    """
    {:ok, modules} = File.read("modules.txt")
    #File.rm!("modules.txt")
    Regex.scan(@module_regex, modules) |> Enum.map(fn([name, _]) -> name end)
  end
end