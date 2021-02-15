defmodule TableTopEx.TicTacToeTest do
  use ExUnit.Case, async: true

  alias TableTopEx.TicTacToe
  doctest TicTacToe

  test "you can have a draw" do
    game = TicTacToe.new()

    moves = [
      {:P1, {0, 0}},
      {:P2, {1, 0}},
      {:P1, {2, 0}},
      {:P2, {2, 1}},
      {:P1, {0, 1}},
      {:P2, {2, 2}},
      {:P1, {1, 1}},
      {:P2, {0, 2}},
      {:P1, {1, 2}}
    ]

    game =
      Enum.reduce(moves, game, fn {player, position}, game ->
        {:ok, game} = TicTacToe.apply_action(game, player, position)
        game
      end)

    assert :draw == TicTacToe.status(game)
    assert moves == TicTacToe.history(game)
  end

  for win <- [
        # Row
        [{0, 0}, {0, 1}, {0, 2}],
        [{1, 0}, {1, 1}, {1, 2}],
        [{2, 0}, {2, 1}, {2, 2}],
        # Column
        [{0, 0}, {1, 0}, {2, 0}],
        [{0, 1}, {1, 1}, {2, 1}],
        [{0, 2}, {1, 2}, {2, 2}],
        # Diagonal
        [{0, 0}, {1, 1}, {2, 2}],
        [{2, 0}, {1, 1}, {0, 2}]
      ] do
    test "#{inspect(win)} is a win" do
      game = TicTacToe.new()

      [x1, x2, x3] = Enum.map(unquote(win), &{:P1, &1})

      [o1, o2] =
        TicTacToe.available(game)
        |> Enum.reject(&(&1 in unquote(win)))
        |> Enum.take(2)
        |> Enum.map(&{:P2, &1})

      game =
        [x1, o1, x2, o2, x3]
        |> Enum.reduce(game, fn {player, position}, game ->
          {:ok, game} = TicTacToe.apply_action(game, player, position)
          game
        end)

      assert {:win, :P1, spaces} = TicTacToe.status(game)
      assert spaces == unquote(win)
    end
  end
end
