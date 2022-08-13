defmodule Jason.Structs.Encoder do
  @moduledoc """
  Implementation that is applied to all the `Jason.Structs` structs.

  Basically it encodes the structs, defined with the DSL provided by `Jason.Structs` to JSON.
  By default all keys are transofrmed from snake-styled expressions to cammel-styled expressions.
  """
  alias Jason.Encoder

  @typep escape :: (String.t(), String.t(), integer() -> iodata())
  @typep encode_map :: (map(), escape(), encode_map() -> iodata())
  @opaque opts :: {escape(), encode_map()}

  @doc """
  Implements the `Jason.Encoder.encode` function for `Jason.Structs` structs.
  """
  @spec encode(data :: map(), opts()) :: iodata()
  def encode(data, options) do
    module = Map.get(data, :__struct__)

    exclude_nils? = Kernel.apply(module, :exclude_nils?, [])
    exclude_empties? = Kernel.apply(module, :exclude_empties?, [])

    to_exclude_if_nil =
      if exclude_nils?,
        do: Map.keys(data),
        else: Kernel.apply(module, :excludable_keys, [])

    data =
      Enum.reduce(to_exclude_if_nil, data, fn key, acc ->
        case Map.get(acc, key) do
          nil ->
            Map.delete(acc, key)

          %{} = map ->
            if exclude_empties? and empty?(map), do: Map.delete(acc, key), else: acc

          _ ->
            acc
        end
      end)

    data
    |> Map.from_struct()
    |> Enum.into(%{}, fn {key, value} -> {key |> Atom.to_string() |> camelize(), value} end)
    |> Encoder.Map.encode(options)
  end

  defp empty?(%{} = struct) when is_struct(struct), do: struct |> Map.from_struct() |> empty?()
  defp empty?(%{} = map) when map_size(map) == 0, do: true
  defp empty?(%{} = map), do: map |> Enum.all?(fn {_, value} -> empty?(value) end)
  defp empty?(nil), do: true
  defp empty?(_), do: false

  defp camelize(str) do
    str = Macro.camelize(str)
    first = str |> String.slice(0..0) |> String.downcase()

    first <> String.slice(str, 1..-1)
  end
end
