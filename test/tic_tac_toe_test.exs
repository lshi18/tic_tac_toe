defmodule TicTacToeTest do
  use ExUnit.Case
  import TicTacToe

  test "Test new_game/0 and quit/1." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game, _} = new_game()
    refute :no_session == TicTacToe.SessionStore.get_session(game)

    {:ok, :ok} = TicTacToe.quit(game)
    assert :no_session == TicTacToe.SessionStore.get_session(game)
  end

  test "Test move/2" do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game, _} = new_game()

    move(game, 3)
    move(game, 4)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test restart/1. It only takes effect when game has finished." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game, _} = new_game()

    move(game, 3)
    s1 = move(game, 4)
    s2 = restart(game)

    assert s1 == s2

    move(game, 2)
    move(game, 7)
    s3 = move(game, 1) |> Map.from_struct
    assert s3[:game_state] == {:win, [{1, 2, 3}]}

    s4 = restart(game) |> Map.from_struct
    assert s4[:game_state] == :playing
    assert s4[:board] == {[], []}

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test start two concurrent games and play concurrently." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game1, _} = new_game()
    {:ok, game2, _} = new_game()

    ## Cross played in square 1 in game 1"
    assert %{board: {[1], []},
             player: :noughts,
             game_state: :playing} == move(game1, 1) |> Map.from_struct

    ## Cross played in square 3 in game 2"
    assert %{board: {[3], []},
             player: :noughts,
             game_state: :playing} == move(game2, 3) |> Map.from_struct

    ## Nought played in square 2 in game 1"
    assert %{board: {[1], [2]},
             player: :crosses,
             game_state: :playing} == move(game1, 2) |> Map.from_struct

    ## Nought played in square 7 in game 2"
    assert %{board: {[3], [7]},
             player: :crosses,
             game_state: :playing} == move(game2, 7) |> Map.from_struct


    ## Game 1 crashed at this point"
    %{routes: routes} = :sys.get_state(TicTacToe.Router)
    :erlang.exit(Map.get(routes, game1), :crashed)

    ## Game 2 should not be affected and cross played in square 6 in game 2.
    assert %{board: {[6, 3], [7]},
             player: :noughts,
             game_state: :playing} == move(game2, 6) |> Map.from_struct

    ## Game 1 should be able to be played from where it left off by reading in session from backend storage.
    assert %{board: {[6, 1], [2]},
             player: :noughts,
             game_state: :playing} == move(game1, 6) |> Map.from_struct

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

end
