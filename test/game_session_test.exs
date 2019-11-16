defmodule TicTacToeGameSessionTest do
  use ExUnit.Case
  alias TicTacToe.GameSession, as: Session

  test "new/0 returns a new session" do
    assert %Session{} == Session.new
  end

  test "invalid move because of it's not an integer in range 1..9" do
    assert {:invalid, :not_integer_in_1_to_9} == Session.move(Session.new, 3.0)
    assert {:invalid, :not_integer_in_1_to_9} == Session.move(Session.new, :atom)
    assert {:invalid, :not_integer_in_1_to_9} == Session.move(Session.new, 1..9)
    assert {:invalid, :not_integer_in_1_to_9} == Session.move(Session.new, "string")
    assert {:invalid, :not_integer_in_1_to_9} == Session.move(Session.new, 'c')
    assert {:invalid, :not_integer_in_1_to_9} == Session.move(Session.new, [:l])
  end

  test "invalid move because of the square has been occupied" do
    assert {:invalid, :move_to_occupied_square} ==
      Session.new |> Session.move(3) |> Session.move(3)
  end

  test "after a move, the game is not finished" do
    assert %Session{board: {[1], [2]},
                    player: :crosses,
                    game_state: :playing} ==
      Session.new
      |> Session.move(1)
      |> Session.move(2)
  end

  test "move after game finished, return an invalid error" do
    finished =
      Session.new
      |> Session.move(3)
      |> Session.move(5)
      |> Session.move(2)
      |> Session.move(4)
      |> Session.move(1)

    assert {:invalid, :move_in_non_playing_state} == finished |> Session.move(6)
    assert {:invalid, :move_in_non_playing_state} == finished |> Session.move(3)
  end

  test "after a move, the crosses wins" do
    assert %Session{board: {[1, 2, 3], [4, 5]},
                    player: :crosses,
                    game_state: {:win, [{1, 2, 3}]}} ==
      Session.new
      |> Session.move(3)
      |> Session.move(5)
      |> Session.move(2)
      |> Session.move(4)
      |> Session.move(1)
  end

  test "after a move, the noughts wins" do
    assert %Session{board: {[7, 2, 3], [6, 4, 5]},
                    player: :noughts,
                    game_state: {:win, [{4, 5, 6}]}} ==
      Session.new
      |> Session.move(3)
      |> Session.move(5)
      |> Session.move(2)
      |> Session.move(4)
      |> Session.move(7)
      |> Session.move(6)
  end

  test "after a move, it draws" do
    assert  %Session{player: :crosses,
                    game_state: :draw,
                    board: {[6, 5, 7, 2, 1], [9, 4, 3, 8]}} ==
      Session.new
      |> Session.move(1)
      |> Session.move(8)
      |> Session.move(2)
      |> Session.move(3)
      |> Session.move(7)
      |> Session.move(4)
      |> Session.move(5)
      |> Session.move(9)
      |> Session.move(6)
  end

  test "after a move, crosses wins at last move" do
    assert %Session{player: :crosses,
                    game_state: {:win, [{1, 4, 7}]},
                    board: {[4, 7, 8, 6, 1], [9, 3, 2, 5]}} ==
      Session.new
      |> Session.move(1)
      |> Session.move(5)
      |> Session.move(6)
      |> Session.move(2)
      |> Session.move(8)
      |> Session.move(3)
      |> Session.move(7)
      |> Session.move(9)
      |> Session.move(4)
  end
end
