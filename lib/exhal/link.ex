defmodule ExHal.Link do
  @moduledoc """
   A Link is a directed reference from one resource to another resource. These
    are found in the `_links` and `_embedded` sections of a HAL document
  """

  defstruct [:rel, :target_url, :templated, :name, :target]

  @doc """
    Build new link struct from _links entry.
  """
  def from_links_entry(rel, a_map) do
    target_url = Map.fetch!(a_map, "href")
    templated  = Map.get(a_map, "templated", false)
    name       = Map.get(a_map, "name", nil)

    %__MODULE__{rel: rel, target_url: target_url, templated: templated, name: name}
  end

  @doc """
    Build new link struct from embedded doc.
  """
  def from_embedded(rel, embedded_doc) do
    {:ok, target_url} = ExHal.url(embedded_doc, fn () -> {:ok, nil} end)

    %__MODULE__{rel: rel, target_url: target_url, templated: false, target: embedded_doc}
  end

  @doc """
    Returns target url, expected with `vars` if any are provied.

    Returns `{:ok, "fully_qualified_url"}`
            `:error` if link target is anonymous
  """
  def target_url(a_link, vars \\ %{}) do
    case a_link do
      %__MODULE__{templated: true} -> {:ok, UriTemplate.expand(a_link.target_url, vars)}
      %__MODULE__{target_url: nil} -> :error
      _                      -> {:ok , a_link.target_url}
    end
  end

  @doc """
    Expands "curie"d link rels using the namespaces found in the `curies` link.

    Returns `[%Link{}, ...]` a link struct for each possible variation of the input link
  """
  def expand_curie(link, namespaces) do
    rel_variations(namespaces, link.rel)
    |> Enum.map(fn rel -> %{link | rel: rel} end)
  end

  
  defp rel_variations(namespaces, rel) do
    {ns, base} = case String.split(rel, ":", parts: 2) do
                   [ns,base] -> {ns,base}
                   [base]    -> {nil,base}
                 end

    case Dict.fetch(namespaces, ns) do
      {:ok, tmpl} -> [rel, UriTemplate.expand(tmpl, rel: base)]
      :error      -> [rel]
    end
  end
end

