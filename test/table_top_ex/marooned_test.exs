defmodule TableTopEx.MaroonedTest do
  use ExUnit.Case, async: true

  alias TableTopEx.Marooned
  doctest Marooned

  test "all valid actions are valid" do
    game = Marooned.new()

    for action <- Marooned.valid_actions(game) do
      assert {:ok, _} = Marooned.apply_action(game, action)
    end
  end

  test "You can play a full game!" do
    game = Marooned.new()

    actions =
      Stream.unfold(game, fn game ->
        case Marooned.status(game) do
          :in_progress ->
            [action | _] = Marooned.valid_actions(game)
            {:ok, game} = Marooned.apply_action(game, action)
            {action, game}

          {:win, _player} ->
            nil
        end
      end)
      |> Enum.to_list()

    assert length(actions) > 0
  end
end
