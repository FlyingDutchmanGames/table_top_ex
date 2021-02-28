defmodule TableTopEx.CrazyEights do
  alias TableTopEx.NifBridge

  @opaque t :: %__MODULE__{}
  @type player :: :P0 | :P1 | :P2 | :P3 | :P4 | :P5 | :P6 | :P7

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @spec new(%{number_of_players: non_neg_integer(), seed: TableTopEx.seed()}) :: t()
  @doc ~S"""
  Creates a new instance of Crazy Eights from some settings

  ## Examples

      iex> %CrazyEights{} = CrazyEights.new(%{number_of_players: 2})

  These only compare equal when the underlying data is the same ref

      iex> game = CrazyEights.new(%{number_of_players: 2})
      iex> game == game
      true
      iex> game == CrazyEights.new(%{number_of_players: 2})
      false
  """
  def new(settings) do
    settings = Map.put_new(settings, :seed, :crypto.strong_rand_bytes(32))
    {:ok, ref} = NifBridge.crazy_eights_new(settings.seed, settings.number_of_players)
    %__MODULE__{_ref: ref}
  end

  @spec whose_turn(t()) :: player()
  @doc ~S"""
  Returns the current player's turn

  ## Examples

      iex> game = CrazyEights.new(%{number_of_players: 2})
      iex> CrazyEights.whose_turn(game)
      :P0
  """
  def whose_turn(%__MODULE__{_ref: ref}) do
    {:ok, player} = NifBridge.crazy_eights_whose_turn(ref)
    player
  end
end
