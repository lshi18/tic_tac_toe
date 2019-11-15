defmodule TicTacToeTest do
  use ExUnit.Case

  test "Test new_game/0 and quit/1." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game, _} = TicTacToe.new_game()
    refute :no_session == TicTacToe.SessionStore.get_session(game)

    {:ok, :ok} = TicTacToe.quit(game)
    assert :no_session == TicTacToe.SessionStore.get_session(game)
  end

  test "Test move/2" do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game, _} = TicTacToe.new_game()

    TicTacToe.move(game, 3)
    TicTacToe.move(game, 4)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test start two concurrent games and play concurrently." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game1, _} = TicTacToe.new_game()
    {:ok, game2, _} = TicTacToe.new_game()

    ## Cross played in square 1 in game 1"
    assert %{board: {[1], []},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game1, 1) |> Map.from_struct

    ## Cross played in square 3 in game 2"
    assert %{board: {[3], []},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game2, 3) |> Map.from_struct

    ## Nought played in square 2 in game 1"
    assert %{board: {[1], [2]},
             player: :crosses,
             game_state: :playing} == TicTacToe.move(game1, 2) |> Map.from_struct

    ## Nought played in square 7 in game 2"
    assert %{board: {[3], [7]},
             player: :crosses,
             game_state: :playing} == TicTacToe.move(game2, 7) |> Map.from_struct


    ## Game 1 crashed at this point"
    %{routes: routes} = :sys.get_state(TicTacToe.Router)
    :erlang.exit(Map.get(routes, game1), :crashed)

    ## Game 2 should not be affected and cross played in square 6 in game 2.
    assert %{board: {[6, 3], [7]},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game2, 6) |> Map.from_struct

    ## Game 1 should be able to be played from where it left off by reading in session from backend storage.
    assert %{board: {[6, 1], [2]},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game1, 6) |> Map.from_struct

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

end
