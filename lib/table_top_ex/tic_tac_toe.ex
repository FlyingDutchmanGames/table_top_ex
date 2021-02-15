defmodule TableTopEx.TicTacToe do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @opaque t :: %__MODULE__{}
  @type player :: :P1 | :P2
  @type position :: {0..2, 0..2}
  @type move :: {player(), position()}

  defguardp on_board?(x) when x in [0, 1, 2]

  @spec new() :: t()
  @doc ~S"""
  Creates a new instance of TicTacToe

      iex> game = %TicTacToe{} = TicTacToe.new()
      iex> TicTacToe.status(game)
      :in_progress
      iex> TicTacToe.available(game)
      [
        {0, 0}, {0, 1}, {0, 2},
        {1, 0}, {1, 1}, {1, 2},
        {2, 0}, {2, 1}, {2, 2}
      ]
  """
  def new() do
    {:ok, ref} = NifBridge.tic_tac_toe_new()
    %__MODULE__{_ref: ref}
  end

  @spec whose_turn(t()) :: player() | nil
  @doc ~S"""
  Returns the player who's turn it is, games always start with `:P1`

      iex> game = TicTacToe.new()
      iex> TicTacToe.whose_turn(game)
      :P1
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      iex> TicTacToe.whose_turn(game)
      :P2
  """
  def whose_turn(%__MODULE__{_ref: ref}) do
    {:ok, turn} = NifBridge.tic_tac_toe_whose_turn(ref)
    turn
  end

  @spec board(t()) :: [[player() | nil]]
  @doc ~S"""
  Returns an Elixir reprensentation of the game board using lists.
  The board is 0 indexed, with the first element of the first list being {0, 0}
  and the last element of the last list being {2, 2}

      iex> game = TicTacToe.new()
      iex> TicTacToe.board(game)
      [
        [nil, nil, nil],
        [nil, nil, nil],
        [nil, nil, nil]
      ]
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 1})
      iex> {:ok, game} = TicTacToe.apply_action(game, :P2, {2, 0})
      iex> TicTacToe.board(game)
      [
        [nil, :P1, nil],
        [nil, nil, nil],
        [:P2, nil, nil]
      ]
  """
  def board(%__MODULE__{_ref: ref}) do
    {:ok, board} = NifBridge.tic_tac_toe_board(ref)
    board
  end

  @spec history(t()) :: [move()]
  @doc ~S"""
  Returns a list of the moves that have been played in this game, in order.

      iex> game = TicTacToe.new()
      iex> TicTacToe.history(game)
      []
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      iex> {:ok, game} = TicTacToe.apply_action(game, :P2, {0, 1})
      iex> TicTacToe.history(game)
      [{:P1, {0, 0}}, {:P2, {0, 1}}]
  """
  def history(%__MODULE__{_ref: ref}) do
    {:ok, history} = NifBridge.tic_tac_toe_history(ref)
    history
  end

  @spec available(t()) :: [position()]
  def available(%__MODULE__{_ref: ref}) do
    {:ok, available} = NifBridge.tic_tac_toe_available(ref)
    available
  end

  @spec status(t()) :: {:win, player(), [position()]} | :in_progress | :draw
  def status(%__MODULE__{_ref: ref}) do
    NifBridge.tic_tac_toe_status(ref)
  end

  @spec at_position(t(), position()) :: player() | nil
  def at_position(game, {col_num, row_num}) when on_board?(col_num) and on_board?(row_num) do
    board(game)
    |> Enum.at(col_num)
    |> Enum.at(row_num)
  end

  def at_position(_game, _position), do: {:error, :position_outside_of_board}

  @spec apply_action(t(), player(), position()) ::
          {:ok, t()} | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
  def apply_action(%__MODULE__{_ref: ref}, player, position) when player in [:P1, :P2] do
    case NifBridge.tic_tac_toe_apply_action(ref, player, position) do
      {:ok, new_ref} when is_reference(new_ref) -> {:ok, %__MODULE__{_ref: new_ref}}
      {:error, err} -> {:error, err}
      err when is_atom(err) -> {:error, err}
    end
  end

  def apply_action(_ref, player, _position) when player not in [:P1, :P2] do
    {:error, :invalid_player}
  end
end
