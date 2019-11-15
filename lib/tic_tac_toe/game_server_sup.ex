defmodule TicTacToe.GameServerSup do
  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def start_child(opts) do
    worker_server_mod = Keyword.fetch!(opts, :worker_server_mod)
    worker_id = Keyword.get(opts, :worker_id)

    worker_spec = %{id: worker_server_mod,
                    start: {worker_server_mod, :start_link, [[worker_id: worker_id]]},
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
    TicTacToe.SessionStore.new()

    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: init_args
    )
  end
end
