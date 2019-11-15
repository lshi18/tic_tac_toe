defmodule TicTacToe.Router do
  use GenServer
  require Logger
  alias TicTacToe.GameServerSup

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def new_game() do
    GenServer.call(__MODULE__, :new_game)
  end

  def route_to(game_id, fun) when is_atom(fun) do
    route_to(game_id, {fun, []})
  end
  def route_to(game_id, {fun, args}) do
    GenServer.call(__MODULE__, {{:route_to, game_id}, {fun, args}})
  end

  def init(game_server_mod: game_server_mod) do
    {:ok, %{routes: %{},
            monitors: %{},
            game_server_mod: game_server_mod}}
  end

  ## c:handle_call/3
  def handle_call(:new_game, _from, state) do
    game_id = make_ref()
    opts = Map.take(state, [:game_server_mod])
    |> Map.to_list
    |> Keyword.put(:game_id, game_id)

    case GameServerSup.start_child(opts) do
      {:ok, game_server_pid} ->
        mon_ref = Process.monitor(game_server_pid)
        %{routes: routes,
          monitors: monitors} = state
        new_state = %{state |
                      routes: Map.put(routes, game_id, game_server_pid),
                      monitors: Map.put(monitors, {mon_ref, game_server_pid}, game_id)
                     }
        {:reply, {:ok, game_id}, new_state}

      other ->
        {:reply, {:error, other}, state}
    end
  end

  def handle_call({{:route_to, game_id}, {fun, args}}, _from, state) do
    %{routes: routes,
      game_server_mod: game_server_mod} = state

    reply =
      case Map.get(routes, game_id) do
        nil ->
          Logger.warn("no route for: #{inspect(game_id)}")
          {:error, :no_such_game}
        game_server when is_pid(game_server) ->
          {:ok, apply(game_server_mod, fun, [game_server | args])}
      end
    {:reply, reply, state}
  end

  ## c:handle_info/2
  def handle_info({:DOWN, mon_ref, :process, pid, {:shutdown, _}}, state) do
    handle_info({:DOWN, mon_ref, :process, pid, :shutdown}, state)
  end

  def handle_info({:DOWN, mon_ref, :process, pid, reason}, state) when reason == :normal or reason == :shutdown do
    %{routes: routes,
      monitors: monitors} = state

    new_state =
      case remove_route_and_monitors(mon_ref, pid, routes, monitors) do
        :not_found ->
          state
        {_game_id, updated_routes, updated_monitors} ->
          %{state |
            routes: updated_routes,
            monitors: updated_monitors}
      end

    {:noreply, new_state}
  end

  def handle_info({:DOWN, mon_ref, :process, pid, reason}, state) do
    %{routes: routes,
      monitors: monitors,
      game_server_mod: game_server_mod} = state

    new_state =
      case remove_route_and_monitors(mon_ref, pid, routes, monitors) do
        :not_found ->
          state
        {game_id, updated_routes, updated_monitors} ->
          case GameServerSup.start_child(
                game_server_mod: game_server_mod,
                game_id: game_id) do
            {:ok, new_pid} ->
              Logger.warn(
                "Game server #{inspect(game_id)} is down with reason #{inspect(reason)}, but automatically restarted."
              )

              new_mon_ref = Process.monitor(new_pid)
              %{state |
                routes: Map.put(updated_routes, game_id, new_pid),
                monitors: Map.put(updated_monitors, {new_mon_ref, new_pid}, game_id)}
            _other ->
              state
          end
      end
    {:noreply, new_state}
  end
  def handle_info(_info, state), do: {:noreply, state}

  ## Helpers
  defp remove_route_and_monitors(mon_ref, pid, routes, monitors) do
    Process.demonitor(mon_ref)
    case Map.pop(monitors, {mon_ref, pid}) do
      {nil, ^monitors} ->
        :not_found
      {game_id, monitors_1} ->
        {^pid, routes_1} = Map.pop(routes, game_id)
        {game_id, routes_1, monitors_1}
    end
  end
end
