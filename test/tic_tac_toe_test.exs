defmodule TicTacToeTest do
  use ExUnit.Case, async: false

  test "Start the application" do
    {:ok, _} = start_supervised({TicTacToe.Supervisor, []})

    {:ok, _game_id, game_state} = TicTacToe.new_game()
    # assert {:ok, %{}} == game_state

    :ok = stop_supervised(TicTacToe.Supervisor)
  end
end
