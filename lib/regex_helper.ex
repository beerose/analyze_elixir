defmodule RegexHelper do  
  
  @module_regex ~r/[A-Z](\w|\.(?:[A-Z]))+(?![:\w\{]|(?:.*\})|(?:.*do))|[A-Z]/
  @module_name_regex ~r/defpmodule\s*(\S+)\s*do/
  @statement_regex ~r/(@moduledoc """(.|\n)*)?#?(import|require|alias|use) ([A-Z]([\w.])+({.*})?(, :\w*)?)/
  @ignored_regex ~r/#.*|"""[\s\S]*?"""|"[^\n]*?"|__[\s\S]*?__/

  @spec get_statements(binary())::list()
  def get_statements(text) do
    Regex.scan(@statement_regex, text)
    |>Enum.reduce([], fn(m, acc) -> [Enum.at(m, 0) | acc] end)
  end

  @spec get_mentions(binary(), string())::list()
  def get_mentions(text, module_name) do
    Regex.scan(@module_regex, text)
    |> Enum.reduce([], fn(m, acc) -> [Enum.at(m, 0) | acc] end)  
    |> Enum.uniq 
    |> Enum.filter(fn(x) -> x != module_name end)
  end

  @spec get_module_names(binary())::list()
  def get_module_names(text) do
    Regex.scan(@module_name_regex, text)
    |> Enum.reduce([], fn(m, acc) -> [Enum.at(m, 1) | acc] end)
  end

  @spec replace_ignored(binary())::binary()
  def replace_ignored(text) do
    Regex.replace(@ignored_regex, text, "")
  end
end