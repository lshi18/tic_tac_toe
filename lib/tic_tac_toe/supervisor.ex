defmodule TicTacToe.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: TicTacToe.Supervisor)
  end

  @impl true
  def init(_init_args) do
    children = [
      {Registry, [keys: :unique, name: Registry.Games]},
      {TicTacToe.GameServerSup, []}
    ]

    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end
end
