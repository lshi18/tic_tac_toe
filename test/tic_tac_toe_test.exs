defmodule TicTacToeTest do
  use ExUnit.Case
  import TicTacToe
  alias TicTacToe.GameSession, as: Session

  test "Test new_game/0 and quit/1." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game} = new_game()
    refute :no_session == TicTacToe.SessionStore.get_session(game)

    {:ok, :ok} = TicTacToe.quit(game)
    assert :no_session == TicTacToe.SessionStore.get_session(game)
  end

  test "Test move/2" do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game} = new_game()

    move(game, 3)
    move(game, 4)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test invalid move." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game} = new_game()

    move(game, :a)
    move(game, 3.0)
    move(game, 1..9)
    move(game, [:a])
    move(game, "a")

    assert %Session{} = restart(game)

    move(game, 1)
    assert %Session{player: :noughts,
                    board: {[1], []}} == move(game, 1)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test move after game finished fails" do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game} = new_game()

    move(game, 1)
    move(game, 4)
    move(game, 2)
    move(game, 5)
    finished_session = move(game, 3)
    assert %Session{game_state: {:win, [{1, 2, 3}]},
                    board: {[3, 2, 1], [5, 4]}} == finished_session
    assert finished_session == move(game, 1)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test restart/1." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game} = new_game()

    move(game, 3)
    move(game, 4)
    assert %Session{} = restart(game)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test game_session/1" do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game} = new_game()

    move(game, 3)
    move(game, 4)
    assert %{board: {[3], [4]},
             player: :crosses,
             game_state: :playing} = game_session(game) |> Map.from_struct

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

  test "Test start two concurrent games and play concurrently." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game1} = new_game()
    {:ok, game2} = new_game()

    ## Cross played in square 1 in game 1"
    assert %Session{board: {[1], []},
             player: :noughts} == move(game1, 1)

    ## Cross played in square 3 in game 2"
    assert %Session{board: {[3], []},
             player: :noughts} == move(game2, 3)

    ## Nought played in square 2 in game 1"
    assert %Session{board: {[1], [2]},
             player: :crosses} == move(game1, 2)

    ## Nought played in square 7 in game 2"
    assert %Session{board: {[3], [7]},
             player: :crosses} == move(game2, 7)


    ## Game 1 crashed at this point"
    %{routes: routes} = :sys.get_state(TicTacToe.Router)
    :erlang.exit(Map.get(routes, game1), :crashed)

    ## Game 2 should not be affected and cross played in square 6 in game 2.
    assert %Session{board: {[6, 3], [7]},
                    player: :noughts,
                    game_state: :playing} == move(game2, 6)

    ## Game 1 should be able to be played from where it left off by reading in session from backend storage.
    assert %Session{board: {[6, 1], [2]},
                    player: :noughts} == move(game1, 6)

    :ok = stop_supervised(TicTacToe.Supervisor)
  end

end
