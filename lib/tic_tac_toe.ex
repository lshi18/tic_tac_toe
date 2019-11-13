defmodule TicTacToe do
  @moduledoc """
  Documentation for TicTacToe.
  """
  require Logger

  @doc """
  Start a new game.
  """
  def new_game() do
    {:ok, game_id} = TicTacToe.Router.new_game()
    Logger.info("New game created: #{inspect(game_id)}")
    {:ok, game_id, TicTacToe.Router.route_to(game_id, :get_game_state)}
  end
end
