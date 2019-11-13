defmodule TicTacToe.GameServerSup do
  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def start_child(opts) do
    game_server_mod = Keyword.fetch!(opts, :game_server_mod)
    game_id = Keyword.get(opts, :game_id)

    worker_spec = %{id: game_server_mod,
                    start: {game_server_mod, :start_link, [[game_id: game_id]]},
                    restart: :temporary
                   }

    case DynamicSupervisor.start_child(__MODULE__, worker_spec) do
      {:ok, pid, _info} ->
        {:ok, pid}
      other ->
        other
    end
  end

  def init(init_args) do
    # :ets.new(:game_state, [:public,
    #                        :named_table,
    #                        :set,
    #                        {:write_concurrency, true}])

    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: init_args
    )
  end
end
