defmodule TableTopEx.TicTacToeTest do
  use ExUnit.Case, async: true

  alias TableTopEx.TicTacToe

  test "You can make a new one" do
    assert %TicTacToe{} = game = TicTacToe.new()
    assert :x = TicTacToe.whose_turn(game)
    assert :in_progress = TicTacToe.status(game)

    assert [{0, 0}, {0, 1}, {0, 2}, {1, 0}, {1, 1}, {1, 2}, {2, 0}, {2, 1}, {2, 2}] =
             TicTacToe.available(game)
  end

  test "You can make a move" do
    assert game = TicTacToe.new()
    assert nil == TicTacToe.at_position(game, {0, 0})
    assert :ok = TicTacToe.make_move(game, :x, {0, 0})
    assert :x = TicTacToe.at_position(game, {0, 0})
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

      [x1, x2, x3] = Enum.map(unquote(win), &{:x, &1})

      [o1, o2] =
        TicTacToe.available(game)
        |> Enum.reject(&(&1 in unquote(win)))
        |> Enum.take(2)
        |> Enum.map(&{:o, &1})

      [x1, o1, x2, o2, x3]
      |> Enum.each(fn {marker, position} ->
        :ok = TicTacToe.make_move(game, marker, position)
      end)

      assert {:win, :x, spaces} = TicTacToe.status(game)
      assert spaces == unquote(win)
    end
  end
end
