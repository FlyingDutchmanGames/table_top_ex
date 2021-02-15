defmodule TableTopEx.NifBridge do
  use Rustler, otp_app: :table_top_ex

  # Tic Tac Toe
  def tic_tac_toe_available(_game), do: err()
  def tic_tac_toe_board(_game), do: err()
  def tic_tac_toe_history(_game), do: err()
  def tic_tac_toe_apply_action(_game, _marker, _position), do: err()
  def tic_tac_toe_new(), do: err()
  def tic_tac_toe_status(_game), do: err()
  def tic_tac_toe_whose_turn(_game), do: err()

  # Marooned
  def marooned_history(_game), do: err()
  def marooned_new(), do: err()
  def marooned_removable(_game), do: err()
  def marooned_removed(_game), do: err()
  def marooned_status(_game), do: err()
  def marooned_whose_turn(_game), do: err()
  def marooned_player_position(_game, _player), do: err()

  defp err do
    :erlang.nif_error(:nif_not_loaded)
  end
end
