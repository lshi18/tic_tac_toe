defmodule TicTacToe.GameServerSup do
  use DynamicSupervisor

  alias TicTacToe.GameServer

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @doc false
  def start_game(name) do
    worker_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [name]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, worker_spec) do
      {:ok, pid, _info} ->
        {:ok, pid}

      other ->
        other
    end
  end

  def init(init_args) do
    TicTacToe.SessionStore.new()

    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: init_args
    )
  end
end
