defmodule TableTopEx.TicTacToe do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @opaque t :: %__MODULE__{}
  @type player :: :P1 | :P2
  @type position :: {0..2, 0..2}
  @type move :: {player(), position()}

  defguardp on_board?(x) when x in [0, 1, 2]

  @doc ~S"""
  Creates a new instance of `TicTacToe`

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
  @spec new() :: t()
  def new() do
    {:ok, ref} = NifBridge.tic_tac_toe_new()
    %__MODULE__{_ref: ref}
  end

  @doc ~S"""
  Returns the player who's turn it is, games always start with `:P1`. This function
  will return a value even if that player can't play because the game is won/drawn.

      iex> game = TicTacToe.new()
      iex> TicTacToe.whose_turn(game)
      :P1
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      iex> TicTacToe.whose_turn(game)
      :P2
  """
  @spec whose_turn(t()) :: player()
  def whose_turn(%__MODULE__{_ref: ref}) do
    {:ok, turn} = NifBridge.tic_tac_toe_whose_turn(ref)
    turn
  end

  @doc ~S"""
  Returns an Elixir reprensentation of the game board using lists.
  The board is `0` indexed, with the first element of the first list being `{0, 0}`
  and the last element of the last list being `{2, 2}`

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
  @spec board(t()) :: [[player() | nil]]
  def board(%__MODULE__{_ref: ref}) do
    {:ok, board} = NifBridge.tic_tac_toe_board(ref)
    board
  end

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
  @spec history(t()) :: [move()]
  def history(%__MODULE__{_ref: ref}) do
    {:ok, history} = NifBridge.tic_tac_toe_history(ref)
    history
  end

  @doc ~S"""
  Returns all the currently open positions

      iex> game = TicTacToe.new()
      iex> TicTacToe.available(game)
      [
        {0, 0}, {0, 1}, {0, 2},
        {1, 0}, {1, 1}, {1, 2},
        {2, 0}, {2, 1}, {2, 2}
      ]
      iex> pos = {0, 0}
      iex> pos in TicTacToe.available(game)
      true
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, pos)
      iex> pos in TicTacToe.available(game)
      false
  """
  @spec available(t()) :: [position()]
  def available(%__MODULE__{_ref: ref}) do
    {:ok, available} = NifBridge.tic_tac_toe_available(ref)
    available
  end

  @doc ~S"""
  Returns the status of the `TicTacToe` game, along with the winning positions if a player has won

      iex> game = TicTacToe.new()
      iex> TicTacToe.status(game)
      :in_progress
  """
  @spec status(t()) :: {:win, player(), [position()]} | :in_progress | :draw
  def status(%__MODULE__{_ref: ref}) do
    NifBridge.tic_tac_toe_status(ref)
  end

  @doc ~S"""
  Returns the occupant of a position if there is one, distinguishing a position from being
  empty and being off of the board. Positions are `0` indexed

      iex> game = TicTacToe.new()
      iex> TicTacToe.at_position(game, {100, 100})
      {:error, :position_outside_of_board}
      iex> TicTacToe.at_position(game, {0, 0})
      nil
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      iex> TicTacToe.at_position(game, {0, 0})
      :P1
  """
  @spec at_position(t(), position()) :: player() | nil | {:error, :position_outside_of_board}
  def at_position(game, {col_num, row_num} = _pos)
      when on_board?(col_num) and on_board?(row_num) do
    board(game)
    |> Enum.at(col_num)
    |> Enum.at(row_num)
  end

  def at_position(_game, _position), do: {:error, :position_outside_of_board}

  @doc ~S"""
  Applies an action to an existing `TicTacToe` game. On success this function returns a new ref
  and does _*NOT*_ mutate the original game. 

  # Examples

  Invalid players are invalid

      iex> game = TicTacToe.new()
      iex> TicTacToe.apply_action(game, :something_random, {0, 0})
      {:error, :invalid_player}

  A player applying an action when it's not their turn is an error

      iex> game = TicTacToe.new()
      iex> TicTacToe.whose_turn(game)
      :P1
      iex> TicTacToe.apply_action(game, :P2, {0, 0})
      {:error, :other_player_turn}

  You can't go in a taken space

      iex> game = TicTacToe.new()
      iex> {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      iex> TicTacToe.apply_action(game, :P2, {0, 0})
      {:error, :space_is_taken}

  You can't go outside the board

      iex> game = TicTacToe.new()
      iex> TicTacToe.apply_action(game, :P1, {100, 100})
      {:error, :position_outside_of_board}

  Other than the above, you can make a move and have it advance the game

      iex> game = TicTacToe.new()
      iex> {:ok, new_game} = TicTacToe.apply_action(game, :P1, {0, 0})
      iex> TicTacToe.at_position(new_game, {0, 0})
      :P1
      iex> game == new_game
      false
  """
  @spec apply_action(t(), player(), position()) ::
          {:ok, t()} | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
  def apply_action(%__MODULE__{_ref: ref} = _game, player, position) when player in [:P1, :P2] do
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
