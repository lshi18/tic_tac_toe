defmodule TicTacToeTest do
  use ExUnit.Case

  test "Test start two concurrent games and play concurrently." do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, game1} = TicTacToe.new_game()
    {:ok, game2} = TicTacToe.new_game()

    IO.puts("## Cross played in square 1 in game 1")
    assert %{board: {[1], []},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game1, 1) |> IO.inspect |> Map.from_struct

    IO.puts("## Cross played in square 3 in game 2")
    assert %{board: {[3], []},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game2, 3) |> IO.inspect |> Map.from_struct

    IO.puts("## Nought played in square 2 in game 1")
    assert %{board: {[1], [2]},
             player: :crosses,
             game_state: :playing} == TicTacToe.move(game1, 2) |> IO.inspect |> Map.from_struct

    IO.puts("## Nought played in square 7 in game 2")
    assert %{board: {[3], [7]},
             player: :crosses,
             game_state: :playing} == TicTacToe.move(game2, 7) |> IO.inspect |> Map.from_struct


    IO.puts("## Game 1 crashed at this point")
    %{routes: routes} = :sys.get_state(TicTacToe.Router)
    :erlang.exit(Map.get(routes, game1), :crashed)

    IO.puts("## Cross played in square 6 in game 2 and game 2 should not be affected")
    assert %{board: {[6, 3], [7]},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game2, 6) |> IO.inspect |> Map.from_struct

    IO.puts("## Game 1 should be played from a good state")
    assert %{board: {[6], []},
             player: :noughts,
             game_state: :playing} == TicTacToe.move(game1, 6) |> IO.inspect |> Map.from_struct

    :ok = stop_supervised(TicTacToe.Supervisor)
  end
end
