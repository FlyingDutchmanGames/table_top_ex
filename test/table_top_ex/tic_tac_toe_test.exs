defmodule TableTopEx.TicTacToeTest do
  use ExUnit.Case, async: true

  alias TableTopEx.TicTacToe

  describe "new/1" do
    test "you can make a new one" do
      assert %TicTacToe{} = game = TicTacToe.new()
      assert :P1 = TicTacToe.whose_turn(game)
      assert :in_progress = TicTacToe.status(game)

      assert [{0, 0}, {0, 1}, {0, 2}, {1, 0}, {1, 1}, {1, 2}, {2, 0}, {2, 1}, {2, 2}] =
               TicTacToe.available(game)

      assert [
               [nil, nil, nil],
               [nil, nil, nil],
               [nil, nil, nil]
             ] == TicTacToe.board(game)
    end
  end

  describe "apply_action/3" do
    test "you can make a move" do
      game = TicTacToe.new()
      assert nil == TicTacToe.at_position(game, {0, 0})
      assert {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      assert :P1 = TicTacToe.at_position(game, {0, 0})

      assert [
               [:P1, nil, nil],
               [nil, nil, nil],
               [nil, nil, nil]
             ] == TicTacToe.board(game)
    end

    test "you can't go if it's not your turn" do
      game = TicTacToe.new()
      assert :P1 = TicTacToe.whose_turn(game)
      assert {:error, :other_player_turn} = TicTacToe.apply_action(game, :P2, {0, 0})
    end

    test "you can't use a marker that's not :P1 or :P2" do
      game = TicTacToe.new()
      assert {:error, :invalid_marker} = TicTacToe.apply_action(game, :random_thingy, {0, 0})
    end

    test "you can't go in a taken space" do
      game = TicTacToe.new()
      assert {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      assert {:error, :space_is_taken} = TicTacToe.apply_action(game, :P2, {0, 0})
    end

    test "you can't go outside the board" do
      game = TicTacToe.new()
      assert {:error, :position_outside_of_board} = TicTacToe.apply_action(game, :P1, {100, 100})
    end
  end

  describe "history/1" do
    test "you can recover the game history" do
      game = TicTacToe.new()
      assert [] == TicTacToe.history(game)
      {:ok, game} = TicTacToe.apply_action(game, :P1, {0, 0})
      assert [{:P1, {0, 0}}] = TicTacToe.history(game)
      {:ok, game} = TicTacToe.apply_action(game, :P2, {0, 1})
      assert [{:P1, {0, 0}}, {:P2, {0, 1}}] = TicTacToe.history(game)
    end
  end

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
      Enum.reduce(moves, game, fn {marker, position}, game ->
        {:ok, game} = TicTacToe.apply_action(game, marker, position)
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
        |> Enum.reduce(game, fn {marker, position}, game ->
          {:ok, game} = TicTacToe.apply_action(game, marker, position)
          game
        end)

      assert {:win, :P1, spaces} = TicTacToe.status(game)
      assert spaces == unquote(win)
    end
  end
end
