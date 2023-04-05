defmodule Exml do
  @moduledoc """
  Module that contains XML string parsing and navigating functions.
  """
  alias Exml.Parsec

  @enforce_keys [:name, :attrs, :children]
  defstruct name: nil, attrs: [], children: []

  @type t() :: Parsec.xml_node()

  @spec parse!(binary()) :: t()
  @doc """
  Parses an XML string.
  """
  def parse!(xml) do
    {:ok, res, "", _, _, _} = Parsec.nodes_to_eos(xml)

    %{
      name: :root,
      attrs: %{},
      children: res
    }
  end

  @spec parse(binary()) :: {:ok, t()} | {:error, String.t()}
  @doc """
  Parses an XML string.
  """
  def parse(xml) do
    with {:ok, res, "", _, _, _} <- Parsec.nodes_to_eos(xml) do
      {:ok,
       %{
         name: :root,
         attrs: %{},
         children: res
       }}
    end
  end

  @spec first(t(), binary()) :: t() | nil
  @doc """
  Return the first occurence of the node with the given name.
  """
  def first(node, name), do: node.children |> Enum.find(fn n -> n.name == name end)

  @spec all(t(), binary()) :: list(t())
  @doc """
  Return all the children of the node with the given name.
  """
  def all(node, name), do: node.children |> Enum.filter(fn n -> n.name == name end)
end
