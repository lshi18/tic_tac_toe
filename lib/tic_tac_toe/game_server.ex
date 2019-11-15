defmodule TicTacToe.GameSession do
  defstruct [player: :crosses,
             board: {[], []},
             game_state: :playing]
end

defmodule TicTacToe.GameServer do
  use GenServer
  require Logger

  alias TicTacToe.GameSession
  alias TicTacToe.SessionStore

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def get_game_state(game_server) do
    GenServer.call(game_server, :get_game_state)
  end

  def move(game_server, n) do
    GenServer.call(game_server, {:move, n})
  end

  def stop(game_server) do
    GenServer.stop(game_server)
  end

  def reset(game_server), do: GenServer.call(game_server, :reset)

  @impl true
  def init(init_args) do
    game_id = Keyword.get(init_args, :game_id)
    session =
      case SessionStore.get_session(game_id) do
        :no_session ->
          SessionStore.init_session(game_id, %GameSession{})
          %GameSession{}
        stored ->
          stored
      end

    {:ok, %{game_id: game_id,
            session: session}}
  end

  @impl true
  def handle_call(:get_game_state, _from, %{session: session} = state) do
    {:reply, session, state}
  end

  def handle_call({:move, n}, _from, %{session: %GameSession{game_state: :playing}} = state) do
    %{game_id: game_id,
      session: %{board: board,
                 player: player} = session} = state

    new_session =
    if valid_move?(board, n) do
      new_session_1 = %{session | board: new_board(player, n, board)}
      case check_for_end(new_session_1) do
        {:win, win} ->
          %{new_session_1 | game_state: {:win, win}}
        :draw ->
          %{new_session_1 | game_state: :draw}
        :playing ->
          %{new_session_1 | player: next_player(player)}
      end
    else
      session
    end
    SessionStore.update_session(game_id, new_session)
    {:reply, new_session, %{state | session: new_session}}
  end

  def handle_call({:move, _}, _from, %{session: session} = state) do
    ## do nothing when moving in non-playing state.
    {:reply, session, state}
  end

  def handle_call(:reset, _from, %{session: %GameSession{game_state: :playing} = session} = state) do
    {:reply, session, state}
  end
  def handle_call(:reset, _from, %{game_id: game_id} = state) do
    new_session = %GameSession{}
    SessionStore.update_session(game_id, new_session)
    {:reply, new_session, %{state | session: new_session}}
  end

  @impl true
  def terminate(_reason, %{game_id: game_id}) do
    SessionStore.delete_session(game_id)
  end

  ## Helper functions
  defp valid_move?({crosses, noughts}, n) do
    (n in 1..9) and (n not in crosses) and (n not in noughts)
  end

  defp check_for_end(%{player: player, board: board}) do
    case {player, board} do
      {:crosses, {crosses, _noughts}} when length(crosses) < 3 ->
        :playing
      {:crosses, {crosses, _noughts}} ->
        case check_for_win(crosses) do
          :playing when length(crosses) == 5 -> :draw
          other -> other
        end
      {:noughts, {_crosses, noughts}} when length(noughts) < 3 ->
        :playing
      {:noughts, {_crosses, noughts}} ->
        check_for_win(noughts)
    end
  end

  defp next_player(:crosses), do: :noughts
  defp next_player(:noughts), do: :crosses

  defp new_board(:crosses, n, {crosses, noughts}), do: {[n | crosses], noughts}
  defp new_board(:noughts, n, {crosses, noughts}), do: {crosses, [n | noughts]}

  defp check_for_win(moves) do
    all_winnings =
      [{1, 2, 3}, {4, 5, 6}, {7, 8, 9},
       {1, 4, 7}, {2, 5, 8}, {3, 6, 9},
       {1, 5, 9}, {3, 5, 7}]

    win =
    for a <- moves, b <- moves, c <- moves, a < b and b < c do
      {a, b, c}
    end
    |> Enum.filter(fn m -> m in all_winnings end)

    if Enum.empty?(win), do: :playing, else: {:win, win}
  end
end

defimpl Inspect, for: TicTacToe.GameSession do

  def inspect(%TicTacToe.GameSession{game_state: game_state,
                                     player: player,
                                     board: {crosses, noughts}}, _opts) do
    cs = Stream.repeatedly(fn -> "X" end) |> Enum.zip(crosses)
    ns = Stream.repeatedly(fn -> "O" end) |> Enum.zip(noughts)
    all = Enum.sort(cs ++ ns, &(elem(&1, 1) < elem(&2, 1)))

    format_fn = fn n ->
      case List.keyfind(all, n, 1) do
        {p, ^n} -> p
        nil -> "_"
      end
    end

    Enum.join(["Game state: #{inspect(game_state)}",
               "Player: #{inspect(player)}",
               "",
               " #{format_fn.(1)} | #{format_fn.(2)} | #{format_fn.(3)} ",
               " #{format_fn.(4)} | #{format_fn.(5)} | #{format_fn.(6)} ",
               " #{format_fn.(7)} | #{format_fn.(8)} | #{format_fn.(9)} ",
               "",
               ""],
      "\n")
  end

end
