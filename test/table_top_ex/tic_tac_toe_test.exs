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

  describe "at_position" do
    test "is nil for an empty space" do
      game = TicTacToe.new()
      assert nil == TicTacToe.at_position(game, {0, 0})
    end

    test "returns an error when you give a position outside the board" do
      game = TicTacToe.new()

      for position <- [{-1, 0}, {4, 0}, {4, 4}] do
        assert {:error, :position_outside_of_board} ==
                 TicTacToe.at_position(game, position)
      end
    end
  end

  describe "copy/1" do
    test "games are mutable 😨😱😈😂" do
      game = TicTacToe.new()
      game_ref = game
      assert nil == TicTacToe.at_position(game, {0, 0})
      assert nil == TicTacToe.at_position(game_ref, {0, 0})

      :ok = TicTacToe.make_move(game, :x, {0, 0})

      assert :x == TicTacToe.at_position(game, {0, 0})
      assert :x == TicTacToe.at_position(game_ref, {0, 0})
    end

    test "you can copy a game" do
      game = TicTacToe.new()
      assert :ok = TicTacToe.make_move(game, :x, {0, 0})
      assert %TicTacToe{} = game_copy = TicTacToe.copy(game)
      assert TicTacToe.board(game) == TicTacToe.board(game_copy)
      assert :ok = TicTacToe.make_move(game, :o, {1, 1})
      refute TicTacToe.board(game) == TicTacToe.board(game_copy)
    end
  end

  describe "make_move/3" do
    test "you can make a move" do
      game = TicTacToe.new()
      assert nil == TicTacToe.at_position(game, {0, 0})
      assert :ok = TicTacToe.make_move(game, :x, {0, 0})
      assert :x = TicTacToe.at_position(game, {0, 0})

      assert [
               [:x, nil, nil],
               [nil, nil, nil],
               [nil, nil, nil]
             ] == TicTacToe.board(game)
    end

    test "you can't go if it's not your turn" do
      assert game = TicTacToe.new()
      assert :x = TicTacToe.whose_turn(game)
      assert {:error, :other_player_turn} = TicTacToe.make_move(game, :o, {0, 0})
    end

    test "you can't use a marker that's not :x or :o" do
      assert game = TicTacToe.new()
      assert {:error, :invalid_marker} = TicTacToe.make_move(game, :random_thingy, {0, 0})
    end

    test "you can't go in a taken space" do
      assert game = TicTacToe.new()
      assert :ok = TicTacToe.make_move(game, :x, {0, 0})
      assert {:error, :space_is_taken} = TicTacToe.make_move(game, :o, {0, 0})
    end

    test "you can't go outside the board" do
      assert game = TicTacToe.new()
      assert {:error, :position_outside_of_board} = TicTacToe.make_move(game, :x, {100, 100})
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

    for {marker, position} <- moves do
      :ok = TicTacToe.make_move(game, marker, position)
    end

    assert :draw == TicTacToe.status(game)
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
