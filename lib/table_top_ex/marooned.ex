defmodule TableTopEx.Marooned do
  alias TableTopEx.NifBridge

  alias __MODULE__.Action

  @opaque t :: %__MODULE__{}
  @type player :: :P1 | :P2
  @type position :: {non_neg_integer(), non_neg_integer()}

  @enforce_keys [:_ref]
  defstruct [:_ref]

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

  @spec history(t()) :: [Action.t()]
  @doc ~S"""
  Returns the history of the game

      iex> game = Marooned.new()
      iex> Marooned.history(game)
      []
  """
  def history(%__MODULE__{_ref: ref} = _game) do
    {:ok, hist} = NifBridge.marooned_history(ref)

    for {player, to, remove} <- hist do
      %Action{player: player, to: to, remove: remove}
    end
  end

  @spec status(t()) :: :in_progress | {:win, player()}
  @doc ~S"""
  Returns the status of the game

      iex> game = Marooned.new()
      iex> Marooned.status(game)
      :in_progress
  """
  def status(%__MODULE__{_ref: ref} = _game) do
    NifBridge.marooned_status(ref)
  end

  @spec player_position(t(), player()) :: position() | {:error, :invalid_player}
  @doc ~S"""
  Returns the position of player

      iex> game = Marooned.new()
      iex> Marooned.player_position(game, :P1)
      {3, 0}
      iex> Marooned.player_position(game, :P2)
      {2, 7}

  Invalid players are invalid

      iex> game = Marooned.new()
      iex> Marooned.player_position(game, :something_random)
      {:error, :invalid_player}
  """
  def player_position(%__MODULE__{_ref: ref} = _game, player) when player in [:P1, :P2] do
    {:ok, position} = NifBridge.marooned_player_position(ref, player)
    position
  end

  def player_position(_game, _player), do: {:error, :invalid_player}

  @spec removed(t()) :: [position()]
  @doc ~S"""
  Returns all the positions that have been removed

      iex> game = Marooned.new()
      iex> Marooned.removed(game)
      []
  """
  def removed(%__MODULE__{_ref: ref} = _game) do
    {:ok, removed} = NifBridge.marooned_removed(ref)
    removed
  end

  @spec removable_for_player(t(), player()) :: [position()] | {:error, :invalid_player}
  @doc ~S"""
  Returns all the positions that are removable for a player,
  you can't remove the position your opponent is standing on,
  but you can remove the one you're standing on.

      iex> game = Marooned.new()
      iex> removable_for_p1 = Marooned.removable_for_player(game, :P1)
      [
        {0, 0}, {0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}, {0, 6}, {0, 7},
        {1, 0}, {1, 1}, {1, 2}, {1, 3}, {1, 4}, {1, 5}, {1, 6}, {1, 7},
        {2, 0}, {2, 1}, {2, 2}, {2, 3}, {2, 4}, {2, 5}, {2, 6},
        {3, 0}, {3, 1}, {3, 2}, {3, 3}, {3, 4}, {3, 5}, {3, 6}, {3, 7},
        {4, 0}, {4, 1}, {4, 2}, {4, 3}, {4, 4}, {4, 5}, {4, 6}, {4, 7},
        {5, 0}, {5, 1}, {5, 2}, {5, 3}, {5, 4}, {5, 5}, {5, 6}, {5, 7}
      ]
      iex> Marooned.player_position(game, :P1) in removable_for_p1
      true
      iex> Marooned.player_position(game, :P2) in removable_for_p1
      false

  Invalid players are invalid

      iex> game = Marooned.new()
      iex> Marooned.player_position(game, :something_random)
      {:error, :invalid_player}
  """
  def removable_for_player(%__MODULE__{_ref: ref} = _game, player) when player in [:P1, :P2] do
    {:ok, removable} = NifBridge.marooned_removable_for_player(ref, player)
    removable
  end

  def player_position(_game, _player), do: {:error, :invalid_player}
end
