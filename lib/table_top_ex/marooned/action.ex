defmodule TableTopEx.Marooned.Action do
  use TypedStruct

  alias TableTopEx.Marooned

  typedstruct enforce: true do
    field(:player, Marooned.player())
    field(:remove, Marooned.position())
    field(:to, Marooned.position())
  end
end
