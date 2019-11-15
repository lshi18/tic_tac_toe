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
    {:ok, game} = TicTacToe.Router.new_game()
    Logger.info("New game created: #{inspect(game)}")
    {:ok, session} = Router.route_to(game, :get_game_state)
    {:ok, game, session}
  end

  @doc """
  Play a move in a specific game.
  """
  def move(game, n) do
    case Router.route_to(game, {:move, [n]}) do
      {:ok, reply} ->
        reply
      {:error, reason} ->
        {:error, reason}
    end
  end

  def restart(game) do
    case Router.route_to(game, :reset) do
      {:ok, reply} ->
        reply
      {:error, reason} ->
        {:error, reason}
    end
  end

  def quit(game) do
    Router.route_to(game, :stop)
  end
end
