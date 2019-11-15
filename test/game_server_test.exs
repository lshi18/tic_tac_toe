defmodule TicTacToeGameServerTest do
  use ExUnit.Case, async: false
  alias TicTacToe.GameServer, as: GS
  alias TicTacToe.GameState, as: State

  test "start a new game" do
    {:ok, pid} = GS.start_link([])
    state = GS.get_game_state(pid)

    assert :crosses == state.player
    assert :playing == state.game_state
    assert {[], []} == state.board

    GS.stop(pid)
  end

  test "play a valid move for each player" do
    {:ok, pid} = GS.start_link([])
    state = GS.move(pid, 3)
    assert %State{player: :noughts,
                  game_state: :playing,
                  board: {[3], []}} == state

    assert %State{player: :crosses,
                  game_state: :playing,
                  board: {[3], [5]}} == GS.move(pid, 5)
    GS.stop(pid)
  end

  test "play invalid moves" do
    {:ok, pid} = GS.start_link([])
    state = GS.move(pid, 11)
    assert %State{player: :crosses,
                  game_state: :playing,
                  board: {[], []}} == state

    ## can't play to the occupied square
    GS.move(pid, 3)
    state = GS.move(pid, 3)
    assert %State{player: :noughts,
                  game_state: :playing,
                  board: {[3], []}} == state

    GS.move(pid, 5)
    state = GS.move(pid, 5)
    assert %State{player: :crosses,
                  game_state: :playing,
                  board: {[3], [5]}} == state

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

    assert %State{player: :crosses,
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
    |> IO.inspect

    assert %State{player: :noughts,
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
    |> IO.inspect

    assert %State{player: :crosses,
                  game_state: :draw,
                  board: {[6, 5, 7, 2, 1], [9, 4, 3, 8]}} == final_state
    GS.stop(pid)
  end

  test "test reset game" do
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

    final_state = GS.reset(pid) |> IO.inspect
    assert %State{player: :crosses,
                  game_state: :playing,
                  board: {[], []}} == final_state
    GS.stop(pid)
  end
end