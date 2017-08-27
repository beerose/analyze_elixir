defmodule Mix.Tasks.AnalyzeElixir do
  @moduledoc """
    AnalyzeElixir is a tool to gather informations about imports in project.
    It stores them in json files consistent with directories given as parameter in format:
      {
        "Module1": {
            "path": path
            "mentions": [...]
            "statements": [...]
        }
        "Module2": {...}
      }
    Where statements stand for explicit imports -- preceded with use | import | alias,
    mentions are any other modules used in current module.
    Usage:
        mix analyze_elixir [directories] [options]
    Example:
        mix analyze_elixir lib web /sth/sth_else
        mix analyze_elixir
    Options:
        -only_local - exludes foreign modules 
  """

  use Mix.Task
  alias RegexHelper
  alias FilesHelper

  @spec run(list())::nil
  def run(directory) do
    local = {Enum.member?(directory, "-only_local"), get_all_modules_in_project()}
    case directory do
        [] -> gather_from_dir(".", local)
        dirs -> Enum.reduce(dirs, 0,  fn(d, _) -> gather_from_dir(d, local) end)
    end
    IO.inspect "Done!"
  end

  @spec gather_from_dir(binary(), {boolean(), any()}):: :ok|{:error, atom()}
  defp gather_from_dir(dir, local) do
    FilesHelper.collect_files_in_dir(dir)
    |> collect_all_imports(%{}, local) 
    |> Poison.encode!(pretty: true)
    |> FilesHelper.write_to_file(dir)
  end

  @spec collect_all_imports(any(), any(), {boolean(), any()})::any()
  defp collect_all_imports(files, acc, local) do
    case files do
      [] -> acc
      [path|t] -> 
        info =
        {path, %{}}
        |> FilesHelper.read_file()
        |> get_all_modules_names(local) # have text and map with module names 
        |> get_file_modules_imports(path)
        collect_all_imports(t, Map.merge(info, acc), local) 
    end
  end 

  @spec get_file_modules_imports({binary(), map()}, string())::map()
  defp get_file_modules_imports({text, info}, path) do
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
            Map.merge(acc, %{name => get_module_imports(text, name, info[name], path)}, 
              fn(_k, v1, v2) -> if v1["mentions"]== [] 
                do v2 else v1 end
              end)
            end)
        Map.merge(info, modules_info)
      info |> Map.to_list |> length == 1 -> 
        [module_name] = info |> Map.keys
        %{module_name => get_module_imports(text, module_name, info[module_name], path)}
      true -> nil
    end
  end

  @spec get_module_imports(binary(), string(), map(), string())::map()
  defp get_module_imports(text, module_name, info, path) do
    text = RegexHelper.replace_ignored(text)
    mentions = RegexHelper.get_mentions(text, module_name)
    statements = RegexHelper.get_statements(text)
    Map.put(info, "mentions", mentions)
    |> Map.put("statements", statements)
    |> Map.put("path", path)
  end

  @spec get_all_modules_names({binary(), any()}, {boolean(), list()})::{binary(), map()}
  defp get_all_modules_names({text, _info}, local) do
    module_names = RegexHelper.get_module_names(text)
    case local do
      {true, local_modules} -> module_names = 
        Enum.filter(module_names, 
        fn(mod) -> Enum.member?(local_modules, mod) end)
      _ -> nil
    end
    {text, make_map_from_modules_names(module_names, %{})}
  end

  @spec make_map_from_modules_names(list(), map())::map()
  defp make_map_from_modules_names(modules_list, acc) do
    case modules_list do
      [] -> acc
      [h|t] -> make_map_from_modules_names(t,
                Map.put(acc, h, %{"mentions" => [], "statements" => [], "path" => ''}))
    end
  end

  @spec get_all_modules_in_project()::list()
  defp get_all_modules_in_project() do
    app_name = Regex.scan(~r/app:\s:(\w+)/, File.read("./mix.exs") |> elem(1))
    |> Enum.at(0) |> Enum.at(1) |> String.to_atom
    Mix.shell.cmd("""
    mix run -e 'IO.inspect(:application.get_key(:#{app_name}, :modules) |> elem(1))' > "modules.txt"
    """)
    {:ok, modules} = File.read("modules.txt")
    File.rm!("modules.txt")
    RegexHelper.get_module_names(modules)
  end
end