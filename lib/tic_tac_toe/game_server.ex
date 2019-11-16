defmodule TicTacToe.GameServer do
  @moduledoc """
  The tic-tac-toe's game server implementation.

  An ets-based session store is used in this implementation,
  so that the session data can survive a crash.
  """

  use GenServer
  require Logger

  alias TicTacToe.GameSession, as: Session
  alias TicTacToe.SessionStore

  @doc false
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @doc false
  def get_game_session(game_server) do
    GenServer.call(game_server, :get_game_session)
  end

  @doc false
  def move(game_server, n) do
    GenServer.call(game_server, {:move, n})
  end

  @doc false
  def stop(game_server) do
    GenServer.stop(game_server)
  end

  @doc false
  def reset(game_server), do: GenServer.call(game_server, :reset)

  @impl true
  def init(init_args) do
    game_id = Keyword.get(init_args, :worker_id)
    session =
      case SessionStore.get_session(game_id) do
        :no_session ->
          new_session = Session.new()
          SessionStore.init_session(game_id, new_session)
          new_session
        stored ->
          stored
      end
    {:ok, %{game_id: game_id,
            session: session}}
  end

  @impl true
  def handle_call(:get_game_session, _from, %{session: session} = state) do
    {:reply, session, state}
  end

  def handle_call({:move, n}, _from, state) do
    %{game_id: game_id,
      session: session} = state

    case Session.move(session, n) do
      {:invalid, reason} ->
        {:reply, {:invalid_move, reason}, state}
      new_session ->
        SessionStore.update_session(game_id, new_session)
        {:reply, new_session, %{state | session: new_session}}
    end
  end

  def handle_call(:reset, _from, %{game_id: game_id} = state) do
    new_session = Session.new()
    SessionStore.update_session(game_id, new_session)
    {:reply, new_session, %{state | session: new_session}}
  end

  @impl true
  def terminate(_reason, %{game_id: game_id}) do
    SessionStore.delete_session(game_id)
  end

end
