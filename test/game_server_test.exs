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

  test "game server to play a complete game " do
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

  test "reset game." do
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

  test "successfully reset an ongoing game." do
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
