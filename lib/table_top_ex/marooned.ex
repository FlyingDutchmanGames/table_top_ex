defmodule TableTopEx.Marooned do
  alias TableTopEx.NifBridge

  alias __MODULE__.{Action, Settings, Settings.Dimensions}

  @opaque t :: %__MODULE__{}
  @type player :: :P1 | :P2
  @type position :: {non_neg_integer(), non_neg_integer()}

  @enforce_keys [:_ref]
  defstruct [:_ref]

  defguardp u8?(x) when x >= 0 and x <= 255

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

  @spec new_from_settings(Settings.t()) :: {:ok, t()} | {:error, :foo}
  @doc ~S"""
  Creates a new instance of marooned from some given settings (or returns an error)

      iex> {:ok, game} = Marooned.new_from_settings(%Marooned.Settings{
      ...>   dimensions: %{rows: 20, cols: 21},
      ...>   starting_removed: [{0, 0}, {1, 1}],
      ...>   p1_starting: {1, 2},
      ...>   p2_starting: {3, 4},
      ...> })
      iex> Marooned.dimensions(game)
      %Marooned.Settings.Dimensions{rows: 20, cols: 21}
      iex> Marooned.removed(game)
      [{0, 0}, {1, 1}]
      iex> Marooned.player_position(game, :P1)
      {1, 2}
      iex> Marooned.player_position(game, :P2)
      {3, 4}

  # Errors

  No dimension may be equal to 0, and rows * cols must be >= 2

      iex> Marooned.new_from_settings(%Marooned.Settings{
      ...>   dimensions: %{ rows: 0, cols: 1 }
      ...> })
      {:error, :invalid_dimensions}
      iex> Marooned.new_from_settings(%Marooned.Settings{
      ...>   dimensions: %{ rows: 1, cols: 1 }
      ...> })
      {:error, :invalid_dimensions}

  You can't remove a posiion off of the board

      iex> Marooned.new_from_settings(%Marooned.Settings{
      ...>   starting_removed: [{250, 250}]
      ...> })
      {:error, :cant_remove_position_not_on_board}

  You can't remove the same position a player is starting at

      iex> Marooned.new_from_settings(%Marooned.Settings{
      ...>   starting_removed: [{0, 0}],
      ...>   p1_starting: {0, 0}
      ...> })
      {:error, :player_cant_start_on_removed_square}

  Players can't start at the same positon

      iex> Marooned.new_from_settings(%Marooned.Settings{
      ...>   p1_starting: {0, 0},
      ...>   p2_starting: {0, 0}
      ...> })
      {:error, :players_cant_start_at_same_position}

  Players must start on the board

      iex> Marooned.new_from_settings(%Marooned.Settings{
      ...>   p1_starting: {50, 50},
      ...> })
      {:error, :players_must_start_on_board}

  """
  def new_from_settings(%Settings{} = settings) do
    dimensions =
      Map.from_struct(%Dimensions{})
      |> Map.merge(settings.dimensions || %{})

    opts = %{
      rows: dimensions.rows,
      cols: dimensions.cols,
      starting_removed: settings.starting_removed
    }

    opts =
      Enum.reduce(~w(p1_starting p2_starting)a, opts, fn key, opts ->
        if val = Map.get(settings, key),
          do: Map.put(opts, key, val),
          else: opts
      end)

    NifBridge.marooned_new_from_settings(opts)
    |> case do
      {:ok, ref} -> {:ok, %__MODULE__{_ref: ref}}
      {:error, err} -> {:error, err}
    end
  end

  @spec whose_turn(t()) :: player()
  @doc ~S"""
  Returns the player who's turn it currently is. All games start with P1.

      iex> game = Marooned.new()
      iex> Marooned.whose_turn(game)
      :P1
  """
  def whose_turn(%__MODULE__{_ref: ref} = _game) do
    {:ok, player} = NifBridge.marooned_whose_turn(ref)
    player
  end

  @spec dimensions(t()) :: Dimensions.t()
  @doc ~S"""
  Returns the dimensions of a game

      iex> game = Marooned.new()
      iex> Marooned.dimensions(game)
      %Marooned.Settings.Dimensions{cols: 6, rows: 8}
  """
  def dimensions(%__MODULE__{_ref: ref} = _game) do
    NifBridge.marooned_dimensions(ref)
    |> Dimensions.from_tuple()
  end

  @spec settings(t()) :: Settings.t()
  @doc ~S"""
  Returns the game settings

      iex> game = Marooned.new()
      iex> Marooned.settings(game)
      %Marooned.Settings{
        dimensions: %Marooned.Settings.Dimensions{cols: 6, rows: 8},
        p1_starting: {3, 0},
        p2_starting: {2, 7},
        starting_removed: []
      }
  """
  def settings(%__MODULE__{_ref: ref} = _game) do
    NifBridge.marooned_settings(ref)
    |> Settings.from_tuple()
  end

  @spec history(t()) :: [Action.t()]
  @doc ~S"""
  Returns the actions applied to the game in order.

      iex> game = Marooned.new()
      iex> Marooned.history(game)
      []
  """
  def history(%__MODULE__{_ref: ref} = _game) do
    {:ok, hist} = NifBridge.marooned_history(ref)
    Enum.map(hist, &Action.from_tuple/1)
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

  @spec allowed_movement_targets_for_player(t(), player()) :: [position()]
  @doc ~S"""

  Allowed movements of a player, this takes into account board dimensions,
  removed positions, and the opponent location.

      iex> game = Marooned.new()
      iex> Marooned.allowed_movement_targets_for_player(game, :P1)
      [{4, 1}, {4, 0}, {3, 1}, {2, 1}, {2, 0}]

  ## Possible Errors

      iex> game = Marooned.new()
      iex> Marooned.allowed_movement_targets_for_player(game, :something_random)
      {:error, :invalid_player}
  """
  def allowed_movement_targets_for_player(%__MODULE__{_ref: ref} = _game, player)
      when player in [:P1, :P2] do
    {:ok, positions} = NifBridge.marooned_allowed_movement_targets_for_player(ref, player)
    positions
  end

  def allowed_movement_targets_for_player(_game, _player), do: {:error, :invalid_player}

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
      iex> Marooned.removable_for_player(game, :something_random)
      {:error, :invalid_player}
  """
  def removable_for_player(%__MODULE__{_ref: ref} = _game, player) when player in [:P1, :P2] do
    {:ok, removable} = NifBridge.marooned_removable_for_player(ref, player)
    removable
  end

  def removable_for_player(_game, _player), do: {:error, :invalid_player}

  @spec is_position_allowed_to_be_removed?(t(), position(), player()) ::
          boolean | {:error, :invalid_player}
  @doc ~S"""
  Fast path test to see if a position is allowed to be removed by a player

      iex> game = Marooned.new()
      iex> Marooned.is_position_allowed_to_be_removed?(game, {3, 3}, :P1)
      true
      iex> p2_position = Marooned.player_position(game, :P2)
      iex> Marooned.is_position_allowed_to_be_removed?(game, p2_position, :P1)
      false

  ## Errors

  This raises when called with an invalid player or a position that doesn't coerce to a (u8, u8)

  """
  def is_position_allowed_to_be_removed?(%__MODULE__{_ref: ref} = _game, position, player) do
    NifBridge.marooned_is_position_allowed_to_be_removed(ref, position, player)
  end

  @spec valid_action(t()) :: {:ok, Action.t()} | nil
  @doc ~S"""
  Returns a valid action. This is optimized under the hood for when you only need one action,
  i.e. having a default for when a player times out

      iex> game = Marooned.new()
      iex> Marooned.valid_action(game)
      {:ok, %TableTopEx.Marooned.Action{player: :P1, remove: {0, 0}, to: {4, 1}}}
  """
  def valid_action(%__MODULE__{_ref: ref} = _game) do
    case NifBridge.marooned_valid_action(ref) do
      {:ok, action_tuple} -> {:ok, Action.from_tuple(action_tuple)}
      nil -> nil
    end
  end

  @spec valid_actions(t()) :: [Action.t()]
  @doc ~S"""
  Returns a list of all the possible valid actions for the next turn. Roughly equal
  to the size of (Number of non removed squares * number of adjacent squares to player)


      iex> game = Marooned.new()
      iex> Marooned.valid_actions(game) |> length
      230
      iex> Marooned.valid_actions(game) |> List.first()
      %Marooned.Action{player: :P1, remove: {0, 0}, to: {4, 1}}
  """
  def valid_actions(%__MODULE__{_ref: ref} = _game) do
    {:ok, actions} = NifBridge.marooned_valid_actions(ref)
    Enum.map(actions, &Action.from_tuple/1)
  end

  @spec apply_action(t(), Action.t()) :: {:ok, t()} | {:error, atom(), String.t()}
  @doc ~S"""
  Applies an action and returns a new game state if successful

  ## Example

      iex> game = Marooned.new()
      iex> Marooned.player_position(game, :P1)
      {3, 0}
      iex> Marooned.removed(game)
      []
      iex> action = %Marooned.Action{to: {3, 1}, remove: {2, 3}, player: :P1}
      iex> {:ok, game} = Marooned.apply_action(game, action)
      iex> Marooned.removed(game)
      [{2, 3}]
      iex> Marooned.player_position(game, :P1)
      {3, 1}

  ## Possible Errors

  You can't apply an action when it's not your turn

      iex> game = Marooned.new()
      iex> Marooned.apply_action(game, %Marooned.Action{player: :P2, to: {1, 2}, remove: {2, 3}})
      {:error, :other_player_turn}

  You have to use a valid player

      iex> game = Marooned.new()
      iex> Marooned.apply_action(game, %Marooned.Action{player: :something_random, to: {1, 2}, remove: {2, 3}})
      {:error, :invalid_player}

  All positions have to be castable as `u8`s

      iex> game = Marooned.new()
      iex> Marooned.apply_action(game, %Marooned.Action{player: :P1, to: {1, 1}, remove: {0, -1}})
      {:error, :invalid_remove}
      iex> Marooned.apply_action(game, %Marooned.Action{player: :P1, to: {100_000, 1}, remove: {0, 0}})
      {:error, :invalid_move_to_target}

  You can't remove a position off the board even if it's a valid u8

      iex> game = Marooned.new()
      iex> Marooned.apply_action(game, %Marooned.Action{player: :P1, to: {3, 1}, remove: {100, 100}})
      {:error, :invalid_remove}

  You can't move to a non adjacent position (or off of the board)

      iex> game = Marooned.new()
      iex> Marooned.apply_action(game, %Marooned.Action{player: :P1, to: {3, 3}, remove: {1, 1}})
      {:error, :invalid_move_to_target}

  You can't remove the same position as you're trying to move to

      iex> game = Marooned.new()
      iex> Marooned.apply_action(game, %Marooned.Action{player: :P1, to: {1, 1}, remove: {1, 1}})
      {:error, :cant_remove_the_same_position_as_move_to}
  """
  def apply_action(_game, %Action{remove: {x, y}}) when not u8?(x) or not u8?(y),
    do: {:error, :invalid_remove}

  def apply_action(_game, %Action{to: {x, y}}) when not u8?(x) or not u8?(y),
    do: {:error, :invalid_move_to_target}

  def apply_action(_game, %Action{player: player}) when player not in [:P1, :P2],
    do: {:error, :invalid_player}

  def apply_action(%__MODULE__{_ref: ref} = _game, %Action{} = action) do
    case NifBridge.marooned_apply_action(ref, Action.to_tuple(action)) do
      {:ok, ref} -> {:ok, %__MODULE__{_ref: ref}}
      err -> err
    end
  end
end
