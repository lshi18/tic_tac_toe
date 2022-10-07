defmodule TicTacToe do
  @moduledoc """
  Documentation for TicTacToe.

  The TicTacToe server is built on TicTacToe.Router and a customizable and configurable
  game server.

  The API provided in this module provides a shell friendly interface for playing the game.
  But it also serves as an example on how to build a front-end utilizing the lower
  level Router API. For more information, please see TicTacToe.Router.

  The 3 x 3 grid is numbered 1 to 9, left to right, and top to bottom:

      1 | 2 | 3
      4 | 5 | 6
      7 | 8 | 9

  Thus, the move/2 function shall receive a number from 1 to 9, and the semantics of which is
  defined as depicted above.

      iex> import TicTacToe
      TicTacToe

      iex> {:ok, game1} = new_game(:a)
      Game state: :playing
      Player: :crosses

      _ | _ | _
      _ | _ | _
      _ | _ | _

      {:ok, :a}

      iex> move(game1, 3)
      Game state: :playing
      Player: :noughts

      _ | _ | X
      _ | _ | _
      _ | _ | _

  Concurrent games can be started and identied by its own game id.

      iex> {:ok, game2} = new_game(:b)
      Game state: :playing
      Player: :crosses

      _ | _ | _
      _ | _ | _
      _ | _ | _

      {:ok, :b}

      iex> move(game2, 5)
      Game state: :playing
      Player: :noughts

      _ | _ | _
      _ | X | _
      _ | _ | _


  If a game server crashes, it will be automatically restarted, and its session data
  will be restored to the point before its crash.

      iex> Registry.dispatch(Registry.Games, :a, fn [{pid, _}] -> :erlang.exit(pid, :crash) end)
      :ok

      ## game1 can be continued to play from the status before its crash.
      iex> move(game1, 7)
      Game state: :playing
      Player: :crosses

      _ | _ | X
      _ | _ | _
      O | _ | _


  When a game session has finished, use restart/1 to explicitly restart the game.

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

  To quit a game, use quit/1 to clean up and release the memory.

      iex> quit(game1)
      :ok
  """
  alias TicTacToe.{GameServerSup, GameServer}

  @type game_id :: atom()
  @type move_result :: TicTacToe.GameSession.t() | {:invalid_move, reason :: term()}

  @doc """
  Start a new game.
  {:ok, game_id} will be returned on success; and {:error, reason} will be returned
  if it fails to start a new game.

  The game_id is the identifier of this game and shall be used in other functions in
  this module.
  """
  @spec new_game(game_id()) :: {:ok, game_id()} | {:error, term()}
  def new_game(name) do
    case GameServerSup.start_game(name) do
      {:ok, _pid} ->
        game_session(name) |> IO.inspect()
        {:ok, name}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieve's current game's session data.
  """
  @spec game_session(game_id()) :: TicTacToe.GameSession.t()
  def game_session(game) do
    session = GameServer.get_game_session(game)
    session
  end

  @doc """
  Play a move in a specific game id,  which should be one returned from new_game/0.

  A valid input should be an integer in range 1 .. 9,
  and it should be a move that has not been played in this game session before.

  If the input is invalid, an error message will be printed and
  then the current game session data will be returned.

  If the input is valid, the updated game session data will be returned.
  """
  @spec move(game_id(), input :: integer()) :: {:ok, move_result()} | {:error, term()}
  def move(name, n) do
    case GameServer.move(name, n) do
      {:invalid_move, :move_in_non_playing_state} ->
        display_error([
          "The game session has finished.\n",
          "To continue, please use TicTacToe.restart/1 to start a new game.\n",
          "To quit, please use TicTacToe.quit/1.\n"
        ])

        game_session(name)

      {:invalid_move, :not_integer_in_1_to_9} ->
        display_error([
          "Invalid move!\n",
          "Please enter an integer between 1 and 9 as your move.\n"
        ])

        game_session(name)

      {:invalid_move, :move_to_occupied_square} ->
        display_error("Square #{n} has been occupied, please make another move.\n")
        game_session(name)

      session ->
        session
    end
  end

  @doc """
  Restart a game with specified game id, which should be one returned from new_game/0.

  If the game has finished (either a draw or won by one party), then calling this function
  will clear the game session data, and return a new one.

  {:error, reason} will be returned if the operation fails.
  """
  @spec restart(game_id()) :: TicTacToe.GameSession.t()
  def restart(name) do
    GameServer.reset(name)
  end

  @doc """
  Quit a game with specified game id, which should be one returned from new_game/0.

  This function should be called at the end of each game's lifetime cycle.

  After the success of this function, the specified game id will become invalid.
  """
  @spec quit(game_id()) :: {:ok, term()} | {:error, term()}
  def quit(game) do
    GameServer.stop(game)
  end

  defp display_error(msg) do
    IO.ANSI.format([:white_background, :red, msg]) |> IO.puts()
  end
end
