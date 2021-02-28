defmodule TableTopEx.CrazyEights.Settings do
  use TypedStruct

  typedstruct do
    field(:number_of_players, 2..8)
    field(:seed, <<_::32>>)
  end

  def from_tuple({seed, number_of_players}) do
    %__MODULE__{
      seed: seed,
      number_of_players: number_of_players
    }
  end
end
