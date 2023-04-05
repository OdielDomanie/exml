defmodule Exml.Parsec do
  @moduledoc """
  NimbleParsec parsers for low level usage.
  """

  import NimbleParsec

  @type xml_node() :: %{
          name: binary() | :root,
          attrs: %{binary() => binary()},
          children: [xml_node() | String.t()]
        }

  identifier = ascii_string([?0..?9, ?a..?z, ?A..?Z, ?:], min: 1)
  w_space = ascii_string([?\s, ?\t, ?\n, ?\r], min: 1)

  closing_tag =
    ignore(string("</"))
    |> unwrap_and_tag(identifier, :closing_name)
    |> optional(ignore(w_space))
    |> ignore(string(">"))

  comment =
    string("<!")
    |> utf8_string([not: ?>], min: 1)
    |> string(">")

  attr =
    ignore(w_space)
    |> tag(identifier, :attr_key)
    |> ignore(string("="))
    |> ignore(string("\""))
    |> tag(
      utf8_string([not: ?\"], min: 1),
      :attr_val
    )
    |> optional(ignore(string("\"")))

  attrs =
    post_traverse(
      repeat(attr),
      :attr_map
    )

  defp add_q(str), do: "?" <> str

  # Processing instructions
  proc_inst =
    ignore(string("<?"))
    |> unwrap_and_tag(
      identifier |> map(:add_q),
      :name
    )
    |> unwrap_and_tag(attrs, :attrs)
    |> ignore(string("?>"))
    |> tag(empty(), :children)
    |> ignore(w_space)
    |> post_traverse(:into_map)

  opening_tag =
    ignore(string("<"))
    |> unwrap_and_tag(
      identifier,
      :name
    )
    |> unwrap_and_tag(attrs, :attrs)
    |> optional(ignore(w_space))
    |> ignore(string(">"))

  defp rm_empty_str(rest, [""], ctx, _, _), do: {rest, [], ctx}
  defp rm_empty_str(rest, res, ctx, _, _), do: {rest, res, ctx}

  defp chr_escape(text) do
    escape_map = %{
      "&quot" => "\"",
      "&apos" => "'",
      "&lt" => "<",
      "&gt" => ">",
      "&amp" => "&"
    }

    for {esc_pat, replacement} <- escape_map, reduce: text do
      text -> String.replace(text, esc_pat, replacement)
    end
  end

  text =
    utf8_string([not: ?<], min: 1)
    |> map({String, :trim, []})
    |> map(:chr_escape)
    |> post_traverse(:rm_empty_str)

  self_closing_tag =
    ignore(string("<"))
    |> unwrap_and_tag(
      identifier,
      :name
    )
    |> unwrap_and_tag(attrs, :attrs)
    |> optional(ignore(w_space))
    |> ignore(string("/>"))
    |> post_traverse(:into_map)

  @doc """
  XML parser/combinator created by the NimbleParsec library.
  """
  defparsec(
    :nodes,
    parsec(:children_wo_text),
    export_combinator: true
  )

  @doc false
  defparsec(
    :nodes_to_eos,
    parsec(:children_wo_text)
    |> eos()
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

  defcombinatorp(
    :node,
    opening_tag
    |> parsec(:children)
    |> concat(closing_tag)
    |> post_traverse(:into_map)
    |> post_traverse(:match_tags)
  )

  defcombinatorp(
    :children_wo_text,
    times(
      choice([
        ignore(comment),
        proc_inst,
        self_closing_tag,
        parsec(:node)
      ]),
      min: 1
    )
  )

  defcombinatorp(
    :children,
    repeat(
      choice([
        parsec(:children_wo_text),
        text
      ])
    )
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
