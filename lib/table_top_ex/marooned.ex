defmodule TableTopEx.Marooned do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @opaque t :: %__MODULE__{}

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
end
