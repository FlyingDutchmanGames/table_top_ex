defmodule TableTopEx.NifBridge do
  use Rustler, otp_app: :table_top_ex

  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_new(), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_available(_game_state), do: :erlang.nif_error(:nif_not_loaded)
  def tic_tac_toe_whose_turn(_game_state), do: :erlang.nif_error(:nif_not_loaded)
end
