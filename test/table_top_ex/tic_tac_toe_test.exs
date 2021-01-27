defmodule TableTopEx.TicTacToeTest do
  use ExUnit.Case, async: true

  alias TableTopEx.TicTacToe

  describe "new/1" do
    test "you can make a new one" do
      assert %TicTacToe{} = game = TicTacToe.new()
      assert :x = TicTacToe.whose_turn(game)
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

  describe "clone/1" do
    test "games are mutable 😨😱😈😂 when using InPlace functions" do
      game = TicTacToe.new()
      game_ref = game
      assert nil == TicTacToe.at_position(game, {0, 0})
      assert nil == TicTacToe.at_position(game_ref, {0, 0})

      :ok = TicTacToe.InPlace.make_move(game, :x, {0, 0})

      assert :x == TicTacToe.at_position(game, {0, 0})
      assert :x == TicTacToe.at_position(game_ref, {0, 0})
    end

    test "you can clone a game" do
      game = TicTacToe.new()
      assert {:ok, game} = TicTacToe.make_move(game, :x, {0, 0})
      assert %TicTacToe{} = game_clone = TicTacToe.InPlace.clone(game)
      assert TicTacToe.board(game) == TicTacToe.board(game_clone)
      assert :ok = TicTacToe.InPlace.make_move(game, :o, {1, 1})
      refute TicTacToe.board(game) == TicTacToe.board(game_clone)
    end

    test "making a move using the safe abstraction does not modify the original ref" do
      game = TicTacToe.new()
      assert {:ok, new_game} = TicTacToe.make_move(game, :x, {0, 0})
      refute TicTacToe.board(game) == TicTacToe.board(new_game)
    end
  end

  describe "make_move/3" do
    test "you can make a move" do
      game = TicTacToe.new()
      assert nil == TicTacToe.at_position(game, {0, 0})
      assert {:ok, game} = TicTacToe.make_move(game, :x, {0, 0})
      assert :x = TicTacToe.at_position(game, {0, 0})

      assert [
               [:x, nil, nil],
               [nil, nil, nil],
               [nil, nil, nil]
             ] == TicTacToe.board(game)
    end

    test "you can't go if it's not your turn" do
      game = TicTacToe.new()
      assert :x = TicTacToe.whose_turn(game)
      assert {:error, :other_player_turn} = TicTacToe.make_move(game, :o, {0, 0})
    end

    test "you can't use a marker that's not :x or :o" do
      game = TicTacToe.new()
      assert {:error, :invalid_marker} = TicTacToe.make_move(game, :random_thingy, {0, 0})
    end

    test "you can't go in a taken space" do
      game = TicTacToe.new()
      assert {:ok, game} = TicTacToe.make_move(game, :x, {0, 0})
      assert {:error, :space_is_taken} = TicTacToe.make_move(game, :o, {0, 0})
    end

    test "you can't go outside the board" do
      game = TicTacToe.new()
      assert {:error, :position_outside_of_board} = TicTacToe.make_move(game, :x, {100, 100})
    end
  end

  describe "undo/1" do
    test "you get `nil` undoing an empty board" do
      game = TicTacToe.new()
      assert {_game, nil} = TicTacToe.undo(game)
    end

    test "you can undo a move" do
      game = TicTacToe.new()
      {:ok, game} = TicTacToe.make_move(game, :x, {0, 0})
      assert [{:x, {0, 0}}] == TicTacToe.history(game)
      assert {game, {:x, {0, 0}}} = TicTacToe.undo(game)
      assert [] == TicTacToe.history(game)
    end

    test "you can undo a move in place" do
      game = TicTacToe.new()
      {:ok, game} = TicTacToe.make_move(game, :x, {0, 0})
      assert [move] = TicTacToe.history(game)
      assert {:ok, ^move} = TicTacToe.InPlace.undo(game)
      assert [] == TicTacToe.history(game)
    end
  end

  describe "history/1" do
    test "you can recover the game history" do
      game = TicTacToe.new()
      assert [] == TicTacToe.history(game)
      {:ok, game} = TicTacToe.make_move(game, :x, {0, 0})
      assert [{:x, {0, 0}}] = TicTacToe.history(game)
      {:ok, game} = TicTacToe.make_move(game, :o, {0, 1})
      assert [{:x, {0, 0}}, {:o, {0, 1}}] = TicTacToe.history(game)
    end
  end

  test "you can have a draw" do
    game = TicTacToe.new()

    moves = [
      {:x, {0, 0}},
      {:o, {1, 0}},
      {:x, {2, 0}},
      {:o, {2, 1}},
      {:x, {0, 1}},
      {:o, {2, 2}},
      {:x, {1, 1}},
      {:o, {0, 2}},
      {:x, {1, 2}}
    ]

    game =
      Enum.reduce(moves, game, fn {marker, position}, game ->
        {:ok, game} = TicTacToe.make_move(game, marker, position)
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

      [x1, x2, x3] = Enum.map(unquote(win), &{:x, &1})

      [o1, o2] =
        TicTacToe.available(game)
        |> Enum.reject(&(&1 in unquote(win)))
        |> Enum.take(2)
        |> Enum.map(&{:o, &1})

      game =
        [x1, o1, x2, o2, x3]
        |> Enum.reduce(game, fn {marker, position}, game ->
          {:ok, game} = TicTacToe.make_move(game, marker, position)
          game
        end)

      assert {:win, :x, spaces} = TicTacToe.status(game)
      assert spaces == unquote(win)
    end
  end
end
