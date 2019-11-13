defmodule TicTacToe.Supervisor do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: TicTacToe.Supervisor)
  end

  @impl true
  def init(init_args) do
    game_server_mod = Keyword.get(init_args, :game_server_mod, TicTacToe.GameServer)

    children = [
      # Starts a worker by calling: TicTacToe.Worker.start_link(arg)
      # {TicTacToe.Worker, arg}
      {TicTacToe.Router, [game_server_mod: game_server_mod]},
      {TicTacToe.GameServerSup, []}
    ]

    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end

end
