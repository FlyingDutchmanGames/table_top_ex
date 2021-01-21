defmodule TableTopEx.TicTacToe do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @type marker :: :x | :o
  @type position :: {0..2, 0..2}

  @spec new() :: %__MODULE__{}
  def new() do
    {:ok, ref} = NifBridge.tic_tac_toe_new()
    %__MODULE__{_ref: ref}
  end

  @spec whose_turn(%__MODULE__{}) :: nil | :x | :o
  def whose_turn(%__MODULE__{_ref: ref}) do
    {:ok, turn} = NifBridge.tic_tac_toe_whose_turn(ref)
    turn
  end

  @spec available(%__MODULE__{}) :: [position()]
  def available(%__MODULE__{_ref: ref}) do
    {:ok, available} = NifBridge.tic_tac_toe_available(ref)
    available
  end

  @spec status(%__MODULE__{}) :: nil
  def status(%__MODULE__{_ref: ref}) do
    NifBridge.tic_tac_toe_status(ref)
  end

  @spec make_move(%__MODULE__{}, marker(), position()) :: :ok | {:error, :space_is_taken}
  def make_move(%__MODULE__{_ref: ref}, marker, position) do
    NifBridge.tic_tac_toe_make_move(ref, marker, position)
  end

  @spec at_position(%__MODULE__{}, position()) :: marker() | nil
  def at_position(%__MODULE__{_ref: ref}, position) do
    {:ok, at} = NifBridge.tic_tac_toe_at_position(ref, position)
    at
  end
end
