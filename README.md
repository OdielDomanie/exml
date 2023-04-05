# Exml

[![ExUnit](https://github.com/OdielDomanie/exml/actions/workflows/elixir.yml/badge.svg)](https://github.com/OdielDomanie/exml/actions/workflows/elixir.yml)

A minimal XML parser library for Elixir, built with NimbleParsec.

The parse result is returned as a transparent Elixir struct.

## Installation

If [available in Hex](https://hex.pm/docs/publish) (not yet), the package can be installed
by adding `exml` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exml, "~> 0.1.0"}
  ]
end
```

~~Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm).~~ Once published, the docs can
be found at <https://hexdocs.pm/exml>.

## Example usage

```elixir
iex> parsed_xml = Exml.parse!(xml_string)

iex> parsed_xml
  |> Exml.first("MPD")
  |> Exml.first("AdaptationSet")
  |> Exml.all("Representation")
  |> Enum.at(2)
  |> Exml.first("AudioChannel")

%Exml{
  name: "AudioChannel",
  attrs: %{"schemeIdUri" => "mpeg:dash"},
  children:
    [
      %Exml{...},
      %Exml{...},
      "Some text"
    ]
}
```

## Limitations

The parser does not check XML document standard conformance, but works at a basic XML language level.
As such, it may accept syntactically correct but not well-formed XML documents.
The parser also does not support some XML features, such as processors.
