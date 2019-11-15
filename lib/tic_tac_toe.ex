defmodule TicTacToe do
  @moduledoc """
  Documentation for TicTacToe.
  """
  require Logger
  alias TicTacToe.Router

  @doc """
  Start a new game.
  """
  def new_game() do
    {:ok, game_id} = TicTacToe.Router.new_game()
    Logger.info("New game created: #{inspect(game_id)}")
    {:ok, state} = Router.route_to(game_id, :get_game_state)
    IO.inspect(state)
    {:ok, game_id}
  end

  @doc """
  Play a move in a specific game.
  """
  def move(game, n) do
    IO.puts("Game ID: #{inspect(game)}")
    case Router.route_to(game, {:move, [n]}) do
      {:ok, reply} ->
        reply
      {:error, reason} ->
        {:error, reason}
    end
  end

  def restart(game) do
    IO.puts("Game ID: #{inspect(game)}")
    case Router.route_to(game, :reset) do
      {:ok, reply} ->
        reply
      {:error, reason} ->
        {:error, reason}
    end
  end
end
