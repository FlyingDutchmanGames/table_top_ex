defmodule TableTopEx.TicTacToe do
  alias __MODULE__.Unsafe
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  defguardp on_board?(x) when x in [0, 1, 2]

  @type marker :: :x | :o
  @type position :: {0..2, 0..2}

  @spec new() :: %__MODULE__{}
  def new() do
    {:ok, ref} = NifBridge.tic_tac_toe_new()
    %__MODULE__{_ref: ref}
  end

  @spec copy(%__MODULE__{}) :: %__MODULE__{}
  def copy(%__MODULE__{_ref: ref}) do
    {:ok, new_ref} = NifBridge.tic_tac_toe_copy(ref)
    %__MODULE__{_ref: new_ref}
  end

  @spec whose_turn(%__MODULE__{}) :: nil | :x | :o
  def whose_turn(%__MODULE__{_ref: ref}) do
    {:ok, turn} = NifBridge.tic_tac_toe_whose_turn(ref)
    turn
  end

  def board(%__MODULE__{_ref: ref}) do
    {:ok, board} = NifBridge.tic_tac_toe_board(ref)
    board
  end

  @spec available(%__MODULE__{}) :: [position()]
  def available(%__MODULE__{_ref: ref}) do
    {:ok, available} = NifBridge.tic_tac_toe_available(ref)
    available
  end

  @spec status(%__MODULE__{}) :: {:win, marker(), [position()]} | :in_progress | :draw
  def status(%__MODULE__{_ref: ref}) do
    NifBridge.tic_tac_toe_status(ref)
  end

  @spec at_position(%__MODULE__{}, position()) :: marker() | nil
  def at_position(%__MODULE__{_ref: ref}, {col, row} = position)
      when on_board?(col) and on_board?(row) do
    {:ok, at} = NifBridge.tic_tac_toe_at_position(ref, position)
    at
  end

  def at_position(_game, _position), do: {:error, :position_outside_of_board}

  @spec make_move(%__MODULE__{}, marker(), position()) ::
          {:ok, %__MODULE__{}}
          | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
  def make_move(game, marker, position) do
    new_game = Unsafe.copy(game)

    case Unsafe.make_move(new_game, marker, position) do
      :ok -> {:ok, new_game}
      err -> err
    end
  end
end
