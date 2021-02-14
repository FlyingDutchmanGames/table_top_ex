defmodule TableTopEx.TicTacToe do
  alias TableTopEx.NifBridge

  @enforce_keys [:_ref]
  defstruct [:_ref]

  @opaque t :: %__MODULE__{}
  @type marker :: :x | :o
  @type position :: {0..2, 0..2}
  @type move :: {marker(), position()}

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

  @spec history(t()) :: [move()]
  def history(%__MODULE__{_ref: ref}) do
    {:ok, history} = NifBridge.tic_tac_toe_history(ref)
    history
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

  @spec apply_action(t(), marker(), position()) ::
          {:ok, t()} | {:error, :space_is_taken | :position_outside_of_board | :other_player_turn}
  def apply_action(%__MODULE__{_ref: ref}, marker, position) do
    case NifBridge.tic_tac_toe_apply_action(ref, marker, position) do
      {:ok, new_ref} when is_reference(new_ref) -> {:ok, %__MODULE__{_ref: new_ref}}
      {:error, err} -> {:error, err}
      err when is_atom(err) -> {:error, err}
    end
  end

  @spec to_json(t()) :: {:ok, String.t()} | {:error, String.t()}
  def to_json(%__MODULE__{_ref: ref}) do
    NifBridge.tic_tac_toe_to_json(ref)
  end

  @spec from_json(String.t()) :: {:ok, %__MODULE__{}} | {:error, String.t()}
  def from_json(json) when is_binary(json) do
    case NifBridge.tic_tac_toe_from_json(json) do
      {:ok, ref} -> {:ok, %__MODULE__{_ref: ref}}
      {:error, err} -> {:error, err}
    end
  end
end
