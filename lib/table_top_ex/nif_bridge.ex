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
  def marooned_new_from_settings(_settings), do: err()
  def marooned_removable_for_player(_game, _player), do: err()
  def marooned_removed(_game), do: err()
  def marooned_status(_game), do: err()
  def marooned_whose_turn(_game), do: err()
  def marooned_player_position(_game, _player), do: err()
  def marooned_apply_action(_game, _action), do: err()
  def marooned_allowed_movement_targets_for_player(_game, _player), do: err()
  def marooned_valid_action(_game), do: err()
  def marooned_valid_actions(_game), do: err()
  def marooned_is_position_allowed_to_be_removed(_game, _position, _player), do: err()
  def marooned_dimensions(_game), do: err()
  def marooned_settings(_game), do: err()

  # Crazy Eights
  def crazy_eights_new(_seed, _number_of_players), do: err()
  def crazy_eights_whose_turn(_game), do: err()
  def crazy_eights_settings(_game), do: err()
  def crazy_eights_status(_game), do: err()

  defp err do
    :erlang.nif_error(:nif_not_loaded)
  end
end
