defmodule TableTopEx.Marooned.Action do
  use TypedStruct

  alias TableTopEx.Marooned

  typedstruct enforce: true do
    field(:player, Marooned.player())
    field(:remove, Marooned.position())
    field(:to, Marooned.position())
  end

  @spec from_tuple({Marooned.player(), Marooned.position(), Marooned.position()}) ::
          __MODULE__.t()
  def from_tuple({player, to, remove}) do
    %__MODULE__{player: player, to: to, remove: remove}
  end

  @spec from_tuple(__MODULE__.t()) ::
          {Marooned.player(), Marooned.position(), Marooned.position()}
  def to_tuple(%__MODULE__{player: player, to: to, remove: remove}) do
    {player, to, remove}
  end
end
