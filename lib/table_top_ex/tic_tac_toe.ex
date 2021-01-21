defmodule TableTopEx.TicTacToe do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  defguardp on_board?(x) when x in [0, 1, 2]
  defguardp valid_marker?(marker) when marker in [:x, :o]

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

  @spec make_move(%__MODULE__{}, marker(), position()) ::
          :ok | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
  def make_move(%__MODULE__{_ref: ref}, marker, {x, y} = position)
      when on_board?(x) and on_board?(y) and valid_marker?(marker) do
    NifBridge.tic_tac_toe_make_move(ref, marker, position)
    |> case do
      :position_outside_of_board = err -> {:error, err}
      result -> result
    end
  end

  def make_move(_game, marker, _position) when valid_marker?(marker),
    do: {:error, :position_outside_of_board}

  def make_move(_game, _marker, _position), do: {:error, :invalid_marker}

  @spec at_position(%__MODULE__{}, position()) :: marker() | nil
  def at_position(%__MODULE__{_ref: ref}, {x, y} = position) when on_board?(x) and on_board?(y) do
    {:ok, at} = NifBridge.tic_tac_toe_at_position(ref, position)
    at
  end

  def at_position(_game, _position), do: {:error, :position_outside_of_board}
end
