defmodule TableTopEx.Marooned.Settings do
  defmodule Dimensions do
    use TypedStruct

    typedstruct enforce: true do
      field(:rows, 0..255, default: 8)
      field(:cols, 0..255, defualt: 6)
    end

    @spec from_tuple({0..255, 0..255}) :: __MODULE__.t()
    def from_tuple({rows, cols}), do: %__MODULE__{rows: rows, cols: cols}

    @spec to_tuple(__MODULE__.t()) :: {0..255, 0..255}
    def to_tuple(%__MODULE__{rows: rows, cols: cols}), do: {rows, cols}
  end

  use TypedStruct

  typedstruct do
    field(:rows, 0..255, default: 3)
    field(:cols, 0..255, default: 4)
    field(:p1_starting, Marooned.position())
    field(:p2_starting, Marooned.position())
    field(:starting_removed_positions, [Marooned.position()], default: [])
  end
end
