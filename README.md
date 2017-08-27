# AnalyzeElixir

AnalyzeElixir is a tool to gather informations about imports in elixir project.
It stores them in json files consistent with directories given as parameter in format:

```
{
 "Module1": {
       "path": path
       "mentions": [...]
       "statements": [...]
      }
 "Module2": {...
      }
}
```
Where statements stand for explicit imports -- preceded with use | import | alias.
Mentions are any other modules used directly in current module.

### Usage:
```mix analyze_elixir [directories] [options]```
     
### Example:
```mix analyze_elixir lib web /sth/sth_else```

```mix analyze_elixir```

### Options:
  *  ```-only_local``` - exludes foreign modules
        
        
## Installation

(https://hex.pm/packages/analyze_elixir), the package can be installed
by adding `analyze_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:analyze_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/analyze_elixir](https://hexdocs.pm/analyze_elixir).

