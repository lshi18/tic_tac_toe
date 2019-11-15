defmodule TicTacToe.Router do
  @moduledoc """
  TicTacToe.Router manages the running of concurrent workers,
  monitors the workers, and automatically restarts any worker
  exiting with a reason other than :normal, :shutdown or
  {:shutdown, _}.

  The worker module is decoupled with the Router implementation
  and is configurable via the init_args of the start_link/1
  function. See start_link/1 for more information.

  The current Router implementation has a dependancy on the
  TicTacToe.GameServerSup and TicTacToe.Supervisor. Though it requires little
  effort to remove this dependancy, this dependancy is preserved for
  simplicity reasons.

  The Router keeps two maps in its state:
  1. Routing information.
    A worker ref => the worker's pid

  2. Monitoring information.
    A tuple of monitoring reference and the worker pid => the worker ref

  The worker id is created when a new worker is started, and is
  available for refering to this worker until the work exits properly.

  The first tuple is used to route request to specific work id to
  its actual pid, because the latter can be susceptible to changes after
  possible crashes.

  The second tuple is used when a worker crashes, under which circumstances
  the Router shall receive notification and update the routing information properly.
  """

  use GenServer
  require Logger
  alias TicTacToe.GameServerSup

  @typep worker_id :: reference()

  @doc """
  Start the router. start_link/1 receives a keyword list, which MUST
  specifies the worker's module through the key :worker_server_mod.
  """
  @spec start_link([worker_server_mod: atom()]) :: GenServer.on_start
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @doc """
  Start a new worker under the GameServerSup supervisor, and sets up
  information so that the router can route messages to and manage the
  worker server.

  On success, it returns the worker's reference.
  """
  @spec new_worker() :: {:ok, worker_id()} | {:error, term()}
  def new_worker() do
    GenServer.call(__MODULE__, :new_worker)
  end

  @doc """
  Route request to the worker instance. In order to successfully route
  messages to the worker server, three information are needed:

  1. the target worker's id (reference), which can be used to retrieve the server's pid;
  2. a function name, or a {function, arguments} tuple;
  3. the worker_server_mod module name.

  where the former two are provided as input to route_to/2, and the last
  one is saved in the router's process.
  """
  @spec route_to(worker_id(), :atom | {:atom, list()}) :: {:ok, term()} | {:error, term()}
  def route_to(worker_id, fun) when is_atom(fun) do
    route_to(worker_id, {fun, []})
  end
  def route_to(worker_id, {fun, args}) do
    GenServer.call(__MODULE__, {{:route_to, worker_id}, {fun, args}})
  end

  @impl true
  def init(worker_server_mod: worker_server_mod) do
    {:ok, %{routes: %{},
            monitors: %{},
            worker_server_mod: worker_server_mod}}
  end

  @impl true
  def handle_call(:new_worker, _from, state) do
    worker_id = make_ref()
    opts = Map.take(state, [:worker_server_mod])
    |> Map.to_list
    |> Keyword.put(:worker_id, worker_id)

    case GameServerSup.start_child(opts) do
      {:ok, worker_server_pid} ->
        mon_ref = Process.monitor(worker_server_pid)
        %{routes: routes,
          monitors: monitors} = state
        new_state = %{state |
                      routes: Map.put(routes, worker_id, worker_server_pid),
                      monitors: Map.put(monitors, {mon_ref, worker_server_pid}, worker_id)
                     }
        {:reply, {:ok, worker_id}, new_state}

      other ->
        {:reply, {:error, other}, state}
    end
  end

  def handle_call({{:route_to, worker_id}, {fun, args}}, _from, state) do
    %{routes: routes,
      worker_server_mod: worker_server_mod} = state

    reply =
      case Map.get(routes, worker_id) do
        nil ->
          Logger.warn("no route for: #{inspect(worker_id)}")
          {:error, :no_such_worker}
        worker_server when is_pid(worker_server) ->
          {:ok, apply(worker_server_mod, fun, [worker_server | args])}
      end
    {:reply, reply, state}
  end

  @impl true
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
        {_worker_id, updated_routes, updated_monitors} ->
          %{state |
            routes: updated_routes,
            monitors: updated_monitors}
      end

    {:noreply, new_state}
  end

  def handle_info({:DOWN, mon_ref, :process, pid, reason}, state) do
    %{routes: routes,
      monitors: monitors,
      worker_server_mod: worker_server_mod} = state

    new_state =
      case remove_route_and_monitors(mon_ref, pid, routes, monitors) do
        :not_found ->
          state
        {worker_id, updated_routes, updated_monitors} ->
          case GameServerSup.start_child(
                worker_server_mod: worker_server_mod,
                worker_id: worker_id) do
            {:ok, new_pid} ->
              Logger.warn(
                "Server #{inspect(worker_id)} is down with reason #{inspect(reason)}, but automatically restarted."
              )

              new_mon_ref = Process.monitor(new_pid)
              %{state |
                routes: Map.put(updated_routes, worker_id, new_pid),
                monitors: Map.put(updated_monitors, {new_mon_ref, new_pid}, worker_id)}
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
      {worker_id, monitors_1} ->
        {^pid, routes_1} = Map.pop(routes, worker_id)
        {worker_id, routes_1, monitors_1}
    end
  end
end
