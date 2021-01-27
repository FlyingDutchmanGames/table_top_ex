defmodule TableTopEx.TicTacToe do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @opaque t :: %__MODULE__{}
  @type marker :: :x | :o
  @type position :: {0..2, 0..2}

  defmodule InPlace do
    alias TableTopEx.TicTacToe

    defguard on_board?(x) when x in [0, 1, 2]
    defguard valid_marker?(marker) when marker in [:x, :o]

    @spec copy(%TicTacToe{}) :: %TicTacToe{}
    def copy(%TicTacToe{_ref: ref}) do
      {:ok, new_ref} = NifBridge.tic_tac_toe_copy(ref)
      %TicTacToe{_ref: new_ref}
    end

    @spec make_move(%TicTacToe{}, TicTacToe.marker(), TicTacToe.position()) ::
            :ok | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
    def make_move(%TicTacToe{_ref: ref}, marker, {col, row} = position)
        when on_board?(col) and on_board?(row) and valid_marker?(marker) do
      NifBridge.tic_tac_toe_make_move(ref, marker, position)
      |> case do
        :position_outside_of_board = err -> {:error, err}
        result -> result
      end
    end

    def make_move(_game, marker, _position) when valid_marker?(marker),
      do: {:error, :position_outside_of_board}

    def make_move(_game, _marker, _position), do: {:error, :invalid_marker}
  end

  defguard on_board?(x) when x in [0, 1, 2]

  @spec new() :: t()
  def new() do
    {:ok, ref} = NifBridge.tic_tac_toe_new()
    %__MODULE__{_ref: ref}
  end

  @spec whose_turn(t()) :: marker() | nil
  def whose_turn(%__MODULE__{_ref: ref}) do
    {:ok, turn} = NifBridge.tic_tac_toe_whose_turn(ref)
    turn
  end

  @spec board(t()) :: [[marker() | nil]]
  def board(%__MODULE__{_ref: ref}) do
    {:ok, board} = NifBridge.tic_tac_toe_board(ref)
    board
  end

  @spec available(t()) :: [position()]
  def available(%__MODULE__{_ref: ref}) do
    {:ok, available} = NifBridge.tic_tac_toe_available(ref)
    available
  end

  @spec status(t()) :: {:win, marker(), [position()]} | :in_progress | :draw
  def status(%__MODULE__{_ref: ref}) do
    NifBridge.tic_tac_toe_status(ref)
  end

  @spec at_position(t(), position()) :: marker() | nil
  def at_position(game, {col_num, row_num}) when on_board?(col_num) and on_board?(row_num) do
    board(game)
    |> Enum.at(col_num)
    |> Enum.at(row_num)
  end

  def at_position(_game, _position), do: {:error, :position_outside_of_board}

  @spec make_move(t(), marker(), position()) ::
          {:ok, t()} | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
  def make_move(game, marker, position) do
    new_game = InPlace.copy(game)

    case InPlace.make_move(new_game, marker, position) do
      :ok -> {:ok, new_game}
      err -> err
    end
  end
end
