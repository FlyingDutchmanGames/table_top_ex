defmodule TableTopEx.Marooned do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @opaque t :: %__MODULE__{}
  @type player :: :P1 | :P2

  @spec new() :: t()
  @doc ~S"""
  Creates a new instance of Marooned with default settings

  ## Examples

  iex> %Marooned{} = Marooned.new()

  These only compare equal when the underlying data is the same ref

  iex> game = Marooned.new()
  iex> game == game
  true
  iex> game == Marooned.new()
  false
  """
  def new() do
    {:ok, ref} = NifBridge.marooned_new()
    %__MODULE__{_ref: ref}
  end

  @spec whose_turn(t()) :: player()
  @doc ~S"""
  Returns the player who's turn it currently is. All games start with P1

      iex> game = Marooned.new()
      iex> Marooned.whose_turn(game)
      :P1
  """
  def whose_turn(%__MODULE__{_ref: ref} = _game) do
    {:ok, player} = NifBridge.marooned_whose_turn(ref)
    player
  end
end
