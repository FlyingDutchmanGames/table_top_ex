defmodule TableTopEx.NifBridge do
  use Rustler, otp_app: :table_top_ex

  def tic_tac_toe_available(_game_state), do: err()
  def tic_tac_toe_board(_game_state), do: err()
  def tic_tac_toe_clone(_game_state), do: err()
  def tic_tac_toe_history(_game_state), do: err()
  def tic_tac_toe_apply_action(_game_state, _marker, _position), do: err()
  def tic_tac_toe_new(), do: err()
  def tic_tac_toe_status(_game_state), do: err()
  def tic_tac_toe_undo(_game_state), do: err()
  def tic_tac_toe_whose_turn(_game_state), do: err()
  def tic_tac_toe_to_json(_game_state), do: err()
  def tic_tac_toe_from_json(_game_state), do: err()
  def tic_tac_toe_to_bincode(_game_state), do: err()
  def tic_tac_toe_from_bincode(_game_state), do: err()

  defp err do
    :erlang.nif_error(:nif_not_loaded)
  end
end
