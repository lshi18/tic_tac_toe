defmodule TicTacToe.GameServer do
  use GenServer
  require Logger

  def start_link(init_args) do
    Logger.debug("game server args: #{inspect(init_args)}")
    GenServer.start_link(__MODULE__, init_args)
  end

  def get_game_state(game_server) do
    GenServer.call(game_server, :get_game_state)
  end

  def stop(game_server), do: GenServer.stop(game_server)

  def init(_init_args) do
    {:ok, %{}}
  end

  def handle_call(:get_game_state, _from, state) do
    {:reply, state, state}
  end
end
