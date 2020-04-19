# Personnummer

Validate Swedish social security numbers with
[Elixir](https://elixir-lang.org/).

## Usage

### Just validation

```elixir
iex(1)> Personnummer.valid?("19900101-0017")
true
```

### Validation and additional information

```elixir
iex(1)> {:ok, pnr} = Personnummer.new("19900101-0017")
{:ok,
 %Personnummer{
   control: 7,
   coordination: false,
   date: ~D[1990-01-01],
   separator: "-",
   serial: 1
 }}
iex(2)> Personnummer.valid?(pnr)
true
iex(3)> gender = if Personnummer.is_female?(pnr) do "female" else "male" end
"male"
iex(4)> IO.puts "The person with social security number #{Personnummer.format(pnr)} is a #{gender} of age #{Personnummer.get_age(pnr)}"
The person with social security number 900101-17 is a male of age 30
:ok
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `personnummer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:personnummer, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/personnummer](https://hexdocs.pm/personnummer).

## Testing

Use `mix test` to run doctests and unit tests.
