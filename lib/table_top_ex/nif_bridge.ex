defmodule TableTopEx.NifBridge do
  use Rustler, otp_app: :table_top_ex

  def tic_tac_toe_available(_game_state), do: err()
  def tic_tac_toe_board(_game_state), do: err()
  def tic_tac_toe_copy(_game_state), do: err()
  def tic_tac_toe_history(_game_state), do: err()
  def tic_tac_toe_make_move(_game_state, _marker, _position), do: err()
  def tic_tac_toe_new(), do: err()
  def tic_tac_toe_status(_game_state), do: err()
  def tic_tac_toe_undo(_game_state), do: err()
  def tic_tac_toe_whose_turn(_game_state), do: err()

  defp err do
    :erlang.nif_error(:nif_not_loaded)
  end
end
