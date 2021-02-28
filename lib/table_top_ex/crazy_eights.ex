defmodule TableTopEx.CrazyEights do
  alias TableTopEx.NifBridge

  @opaque t :: %__MODULE__{}

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @spec new(%{number_of_players: non_neg_integer(), seed: TableTopEx.seed()}) :: t()
  @doc ~S"""
  Creates a new instance of Crazy Eights from some settings

  ## Examples

      iex> %CrazyEights{} = CrazyEights.new(%{
      ...>   number_of_players: 2,
      ...>   seed: :crypto.strong_rand_bytes(32)
      ...> })

  These only compare equal when the underlying data is the same ref

      iex> settings = %{number_of_players: 2, seed: :crypto.strong_rand_bytes(32)}
      iex> game = CrazyEights.new(settings)
      iex> game == game
      true
      iex> game == CrazyEights.new(settings)
      false
  """
  def new(%{number_of_players: number_of_players, seed: seed})
      when is_binary(seed) and byte_size(seed) == 32 and number_of_players in 2..8 do
    {:ok, ref} = NifBridge.crazy_eights_new(seed, number_of_players)
    %__MODULE__{_ref: ref}
  end
end
