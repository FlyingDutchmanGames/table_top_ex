defmodule TableTopEx.Marooned.Settings do
  defmodule Dimensions do
    @enforce_keys [:rows, :cols]
    defstruct rows: 8, cols: 6
  end
end
