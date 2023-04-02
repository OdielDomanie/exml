defmodule Exml do
  import NimbleParsec

  @type xml_node() :: %{
          name: binary() | :root,
          attrs: %{binary() => binary()},
          children: [xml_node()]
        }

  @spec parse!(binary()) :: xml_node()
  @doc """
  Parses an XML string.
  """
  def parse!(xml) do
    {:ok, res, "", _, _, _} = nodes(xml)

    %{
      name: :root,
      attrs: %{},
      children: res
    }
  end

  @doc """
  XML parser/combinator created by the NimbleParsec library.
  """
  defparsec(:nodes, repeat(parsec(:node)), export_combinator: true)

  identifier = ascii_string([?0..?9, ?a..?z, ?A..?Z], min: 1)
  w_space = ascii_string([32, ?\n], min: 1)

  closing_tag =
    ignore(string("</")) |> unwrap_and_tag(identifier, :closing_name) |> ignore(string(">"))

  attr =
    ignore(w_space)
    |> tag(identifier, :attr_key)
    |> ignore(string("="))
    |> ignore(string("\""))
    |> tag(
      # all unicode except double-quote
      repeat(utf8_string([32..33, 35..0x10FFFF], min: 1)),
      :attr_val
    )
    |> ignore(string("\""))

  attrs =
    post_traverse(
      repeat(attr),
      :attr_map
    )

  defp attr_map(rest, attrs, ctx, _, _) do
    attrs_map =
      attrs
      |> Enum.reverse()
      |> Enum.chunk_every(2)
      |> Enum.into(
        %{},
        fn [attr_key: [k], attr_val: [v]] ->
          {k, v}
        end
      )

    {rest, [attrs_map], ctx}
  end

  opening_tag =
    ignore(string("<"))
    |> unwrap_and_tag(identifier, :name)
    |> unwrap_and_tag(attrs, :attrs)
    |> ignore(string(">"))

  text = ascii_string([not: ?<], min: 1)

  defcombinatorp(
    :node,
    opening_tag
    |> parsec(:children)
    |> concat(closing_tag)
    |> post_traverse(:into_map)
    |> post_traverse(:match_tags)
  )

  defcombinatorp(
    :children,
    repeat(choice([parsec(:node), text]))
    |> tag(:children)
  )

  defp into_map(rest, kw, ctx, _line, _offset), do: {rest, [Map.new(kw)], ctx}

  defp match_tags(rest, [%{name: name, closing_name: name} = tags], ctx, _line, _offset) do
    {rest, [Map.delete(tags, :closing_name)], ctx}
  end

  defp match_tags(_rest, [%{name: name, closing_name: closing_name}], _ctx, _line, _offset)
       when name != closing_name do
    {:error, "closing tag #{inspect(closing_name)} did not match opening tag #{inspect(name)}"}
  end
end
