defmodule TicTacToeGameServerTest do
  use ExUnit.Case
  alias TicTacToe.GameServer, as: GS
  alias TicTacToe.GameSession, as: Session

  test "start a new game" do
    {:ok, pid} = GS.start_link([])
    assert %Session{} = GS.get_game_session(pid)

    GS.stop(pid)
  end

  test "play a valid move for each player" do
    {:ok, pid} = GS.start_link([])
    state = GS.move(pid, 3)
    assert %Session{player: :noughts,
                    game_state: :playing,
                    board: {[3], []}} == state

    assert %Session{player: :crosses,
                    game_state: :playing,
                    board: {[3], [5]}} == GS.move(pid, 5)
    GS.stop(pid)
  end

  test "invalid move not in the range of 1 .. 9" do
    {:ok, pid} = GS.start_link([])

    assert {:invalid_move, :integer_in_1_to_9} == GS.move(pid, 10)
    assert {:invalid_move, :integer_in_1_to_9} = GS.move(pid, 3.0)

    GS.stop(pid)
  end

  test "invalid move to occupied squares" do
    {:ok, pid} = GS.start_link([])

    GS.move(pid, 5)
    assert {:invalid_move, :move_to_occupied_square} = GS.move(pid, 5)

    GS.stop(pid)
  end

  test "invalid move after the game has finished." do
    {:ok, pid} = GS.start_link([])

    moves = [{:c, 1}, {:n, 5},
             {:c, 2}, {:n, 4},
             {:c, 3}]

    for {_player, move} <- moves do
      GS.move(pid, move)
    end
    |> List.last

    assert {:invalid_move, :move_in_non_playing_state} = GS.move(pid, 6)
    GS.stop(pid)
  end

  test "test crosses win at last step" do
    {:ok, pid} = GS.start_link([])

    moves = [{:c, 1}, {:n, 5},
             {:c, 6}, {:n, 2},
             {:c, 8}, {:n, 3},
             {:c, 7}, {:n, 9},
             {:c, 4}]

    final_state =
    for {_player, move} <- moves do
      GS.move(pid, move)
    end
    |> List.last

    assert %Session{player: :crosses,
                    game_state: {:win, [{1, 4, 7}]},
                    board: {[4, 7, 8, 6, 1], [9, 3, 2, 5]}} == final_state
    GS.stop(pid)
  end

  test "test noughts win after 4 moves" do
    {:ok, pid} = GS.start_link([])

    moves = [{:c, 1}, {:n, 4},
             {:c, 7}, {:n, 5},
             {:c, 3}, {:n, 8},
             {:c, 9}, {:n, 6}]

    final_state =
    for {_player, move} <- moves do
      GS.move(pid, move)
    end
    |> List.last

    assert %Session{player: :noughts,
                    game_state: {:win, [{4, 5, 6}]},
                    board: {[9, 3, 7, 1], [6, 8, 5, 4]}} == final_state

    GS.stop(pid)
  end

  test "test draw" do
    {:ok, pid} = GS.start_link([])

    moves = [{:c, 1}, {:n, 8},
             {:c, 2}, {:n, 3},
             {:c, 7}, {:n, 4},
             {:c, 5}, {:n, 9},
             {:c, 6}]

    final_state =
    for {_player, move} <- moves do
      GS.move(pid, move)
    end
    |> List.last

    assert %Session{player: :crosses,
                    game_state: :draw,
                    board: {[6, 5, 7, 2, 1], [9, 4, 3, 8]}} == final_state
    GS.stop(pid)
  end

  test "test reset game." do
    {:ok, pid} = GS.start_link([])

    moves = [{:c, 1}, {:n, 8},
             {:c, 2}, {:n, 3},
             {:c, 7}, {:n, 4},
             {:c, 5}, {:n, 9},
             {:c, 6}]

    final_state =
    for {_player, move} <- moves do
      GS.move(pid, move)
    end |> List.last

    assert final_state.game_state == :draw

    final_state = GS.reset(pid)
    assert %Session{player: :crosses,
                    game_state: :playing,
                    board: {[], []}} == final_state

    GS.stop(pid)
  end

  test "test successfully reset an ongoing game." do
    {:ok, pid} = GS.start_link([])
    moves = [{:c, 1}, {:n, 8},
             {:c, 2}, {:n, 3},
             {:c, 7}]

    for {_player, move} <- moves do
      GS.move(pid, move)
    end |> List.last

    assert %Session{}= GS.reset(pid)

    GS.stop(pid)
  end
end
