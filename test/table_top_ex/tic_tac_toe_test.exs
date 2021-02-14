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

  describe "apply_action/3" do
    test "you can make a move" do
      game = TicTacToe.new()
      assert nil == TicTacToe.at_position(game, {0, 0})
      assert {:ok, game} = TicTacToe.apply_action(game, :x, {0, 0})
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
      assert {:error, :other_player_turn} = TicTacToe.apply_action(game, :o, {0, 0})
    end

    test "you can't use a marker that's not :x or :o" do
      game = TicTacToe.new()
      assert {:error, :invalid_marker} = TicTacToe.apply_action(game, :random_thingy, {0, 0})
    end

    test "you can't go in a taken space" do
      game = TicTacToe.new()
      assert {:ok, game} = TicTacToe.apply_action(game, :x, {0, 0})
      assert {:error, :space_is_taken} = TicTacToe.apply_action(game, :o, {0, 0})
    end

    test "you can't go outside the board" do
      game = TicTacToe.new()
      assert {:error, :position_outside_of_board} = TicTacToe.apply_action(game, :x, {100, 100})
    end
  end

  describe "history/1" do
    test "you can recover the game history" do
      game = TicTacToe.new()
      assert [] == TicTacToe.history(game)
      {:ok, game} = TicTacToe.apply_action(game, :x, {0, 0})
      assert [{:x, {0, 0}}] = TicTacToe.history(game)
      {:ok, game} = TicTacToe.apply_action(game, :o, {0, 1})
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

      [x1, x2, x3] = Enum.map(unquote(win), &{:x, &1})

      [o1, o2] =
        TicTacToe.available(game)
        |> Enum.reject(&(&1 in unquote(win)))
        |> Enum.take(2)
        |> Enum.map(&{:o, &1})

      game =
        [x1, o1, x2, o2, x3]
        |> Enum.reduce(game, fn {marker, position}, game ->
          {:ok, game} = TicTacToe.apply_action(game, marker, position)
          game
        end)

      assert {:win, :x, spaces} = TicTacToe.status(game)
      assert spaces == unquote(win)
    end
  end

  describe "json" do
    test "You can {de}serialize an empty game" do
      game = TicTacToe.new()
      assert {:ok, "{\"history\":[]}" = json} = TicTacToe.to_json(game)
      {:ok, new_game} = TicTacToe.from_json(json)
      assert [] == TicTacToe.history(new_game)
    end

    test "You can serialize a game with moves" do
      game = TicTacToe.new()
      assert {:ok, game} = TicTacToe.apply_action(game, :x, {0, 0})
      assert {:ok, game} = TicTacToe.apply_action(game, :o, {1, 1})
      assert {:ok, game} = TicTacToe.apply_action(game, :x, {2, 2})
      assert {:ok, "{\"history\":[[0,0],[1,1],[2,2]]}" = json} = TicTacToe.to_json(game)
      {:ok, new_game} = TicTacToe.from_json(json)
      assert [x: {0, 0}, o: {1, 1}, x: {2, 2}] == TicTacToe.history(new_game)
    end

    test "invalid json yields an error" do
      assert {:error, "expected value at line 1 column 1"} = TicTacToe.from_json("invalid-json")
      assert {:error, "missing field `history` at line 1 column 2"} = TicTacToe.from_json("{}")

      assert {:error, "invalid type: integer `1`, expected a sequence at line 1 column 13"} =
               TicTacToe.from_json("{\"history\": 1}")
    end
  end

  describe "bincode" do
    test "You can {de}serialize an empty game" do
      game = TicTacToe.new()
      assert {:ok, <<0, 0, 0, 0, 0, 0, 0, 0>> = bincode} = TicTacToe.to_bincode(game)
      {:ok, new_game} = TicTacToe.from_bincode(bincode)
      assert [] == TicTacToe.history(new_game)
    end

    test "You can serialize a game with moves" do
      game = TicTacToe.new()
      assert {:ok, game} = TicTacToe.apply_action(game, :x, {0, 0})
      assert {:ok, game} = TicTacToe.apply_action(game, :o, {1, 1})
      assert {:ok, game} = TicTacToe.apply_action(game, :x, {2, 2})

      assert {:ok, <<3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2>> = bincode} =
               TicTacToe.to_bincode(game)

      {:ok, new_game} = TicTacToe.from_bincode(bincode)
      assert [x: {0, 0}, o: {1, 1}, x: {2, 2}] == TicTacToe.history(new_game)
    end

    test "invalid bincode yields an error" do
      assert {:error, "invalid value: 98, expected one of: 0, 1, 2"} =
               TicTacToe.from_bincode("invalid-bincode")

      assert {:error, "io error: unexpected end of file"} =
               TicTacToe.from_bincode(<<0, 1, 2, 3, 4>>)
    end
  end
end
