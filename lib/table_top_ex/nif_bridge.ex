defmodule TableTopEx.NifBridge do
  use Rustler, otp_app: :table_top_ex

  def tic_tac_toe_new(), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_available(_game_state), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_whose_turn(_game_state), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_status(_game_state), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_at_position(_game_state, _position), do: :erlang.nif_error(:nif_not_loaded)

  def tic_tac_toe_make_move(_game_state, _marker, _position),
    do: :erlang.nif_error(:nif_not_loaded)
end
