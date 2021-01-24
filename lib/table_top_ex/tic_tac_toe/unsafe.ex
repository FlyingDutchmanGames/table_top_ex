defmodule TableTopEx.TicTacToe.Unsafe do
  alias TableTopEx.{TicTacToe, NifBridge}

  defguardp on_board?(x) when x in [0, 1, 2]
  defguardp valid_marker?(marker) when marker in [:x, :o]

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
