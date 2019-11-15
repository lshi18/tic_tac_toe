defmodule TicTacToe do
  @moduledoc """
  Documentation for TicTacToe.

  This module provides an API which is a thin wrapper based on TicTacToe.Router, to
  facilitate playing the tic-tac-toe game in the elixir shell (start with "iex -S mix").
  But the API in this module also serves as a backend service, which facilitate
  the building of the tic-tac-toe game's frontend.

  The 3 x 3 grid is numbered 1 to 9, left to right, and top to bottom:

      1 | 2 | 3
      4 | 5 | 6
      7 | 8 | 9

  Thus, the move/2 function shall receive a number from 1 to 9, and the semantics of which is
  defined as depicted above.

      iex> import TicTacToe
      TicTacToe

      iex> {:ok, game1, _session} = new_game()
      {:ok, #Reference<0.3646061956.1345847299.109215>,
       Game state: :playing
       Player: :crosses

       _ | _ | _
       _ | _ | _
       _ | _ | _

      }

      iex> move(game1, 3)
      Game state: :playing
      Player: :noughts

      _ | _ | X
      _ | _ | _
      _ | _ | _

  Concurrent games can be started and identied by its own game id.

      iex> {:ok, game2, _session} = new_game()
      {:ok, #Reference<0.3646061956.1345847299.109312>,
       Game state: :playing
       Player: :crosses

       _ | _ | _
       _ | _ | _
       _ | _ | _

      }

      iex> move(game2, 5)
      Game state: :playing
      Player: :noughts

      _ | _ | _
      _ | X | _
      _ | _ | _


  If a game server crashes, it will be automatically restarted, and its session data
  will be restored to the point before its crash.

      iex> pid_for_game1 = :sys.get_state(TicTacToe.Router) |> Map.get(:routes) |> Map.get(game1)
      iex> :erlang.exit(pid_for_game1, :crashed)
      true

      ## game1 can be continued to play from the status before its crash.
      iex> move(game1, 7)
      Game state: :playing
      Player: :crosses

      _ | _ | X
      _ | _ | _
      O | _ | _


  When a game has played out, use restart/1 to explicitly restart the game.

      iex> move(game1, 6)
      Game state: {:win, [{1, 5, 9}]}
      Player: :crosses

      X | X | O
      O | X | _
      O | _ | X

      iex> restart(game1)
      Game state: :playing
      Player: :crosses

      _ | _ | _
      _ | _ | _
      _ | _ | _

  To quit a game, use quit/1 to clean up and release memory.

      iex> quit(game1)
      {:ok, :ok}

  """
  require Logger
  alias TicTacToe.Router

  @type game_id :: reference()

  @doc """
  Start a new game via the TicTacToe.Router. {:ok, game_id, session} will be returned
  on success; and {:error, reason} will be returned if it fails to start a new game.

  The game_id is the identifier of this game and shall be used in other functions in
  this module.
  """
  @spec new_game() :: {:ok, game_id(), TicTacToe.GameSession.t} | {:error, term()}
  def new_game() do
    case TicTacToe.Router.new_worker() do
      {:ok, game} ->
        Logger.info("New game created: #{inspect(game)}")
        {:ok, session} = Router.route_to(game, :get_game_state)
        {:ok, game, session}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Play a move in a specific game id,  which should be one returned from new_game/0.

  A valid input should be an integer in range 1 .. 9,
  and it should be a move that has not been played in this game session before.

  If the input is invalid, then the current game session data is returned without
  any updates.

  If the input is valid, the updated game session data will be returned.

  {:error, reason} will be returned if the operation fails.
  """
  @spec move(game_id(), input :: integer()) :: TicTacToe.GameSession.t | {:error, term()}
  def move(game, n) do
    case Router.route_to(game, {:move, [n]}) do
      {:ok, reply} ->
        reply
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Restart a game with specified game id, which should be one returned from new_game/0.

  If the game has finished (either a draw or won by one party), then calling this function
  will clear the game session data, and return a new one.

  If the game is still in the "playing" state, then the game will not be restarted,
  and the current game session data is returned.

  {:error, reason} will be returned if the operation fails.
  """
  @spec restart(game_id()) :: TicTacToe.GameSession.t | {:error, term()}
  def restart(game) do
    case Router.route_to(game, :reset) do
      {:ok, reply} ->
        reply
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Quit a game with specified game id, which should be one returned from new_game/0.

  This function should be called at the end of each game's lifetime cycle.

  After the success of this function, the specified game id will become invalid.
  """
  @spec quit(game_id()) :: {:ok, term()} | {:error, term()}
  def quit(game) do
    Router.route_to(game, :stop)
  end
end
