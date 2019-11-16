defmodule TicTacToe.GameSession do
  @moduledoc """
  This module contains the main logic of the tic-tac-toe game.
  It has two public functions: new/0 and move/2.
  """

  defstruct [player: :crosses,
             board: {[], []},
             game_state: :playing]

  @type t :: %__MODULE__{
    player: :crosses | :noughts,
    board: {list(integer), list(integer)},
    game_state: :playing | :draw | {:win, list({integer, integer, integer})}
  }

  @doc """
  Returns a new game session.
  """
  @spec new() :: t()
  def new(), do: %__MODULE__{}

  @doc """
  Make a move n to the current session and returns a new session.

  Each move will update the board.

  If after the move, neither side wins nor it draws, then player will be updated to indicate
  that the next player should be playing.

  If after the move, the move maker wins, then the game_state will be updated to {:win, data}
  when data is a list of triples, and each triple represents the squares in a row.

  If after the move, it draws, then the game_state will update to :draw.

  If the move is invalid, {:invalid, reason} will be returned, where reason can be
  :not_integer_in_1_to_9, :move_to_occupied_square or :move_in_non_playing_state.
  """
  @spec move(t(), integer) :: t() | {:invalid, reason}
  when reason: :not_integer_in_1_to_9 | :move_to_occupied_square | :move_in_non_playing_state
  def move(%__MODULE__{player: player, board: board} = session, n) do
    case check_valid_move(session, n) do
      :valid ->
        board_after_move = new_board(player, n, board)
        new_session = %{session | board: board_after_move}
        case check_for_end(player, board_after_move) do
          {:win, win} ->
            %{new_session | game_state: {:win, win}}
          :draw ->
            %{new_session | game_state: :draw}
          :playing ->
            %{new_session | player: next_player(player)}
        end
      {:invalid, _reason} = invalid ->
        invalid
    end
  end

  defp check_valid_move(%__MODULE__{game_state: gs}, _n) when gs !== :playing,
    do: {:invalid, :move_in_non_playing_state}
  defp check_valid_move(_sesion, n) when n not in 1 .. 9 do
    {:invalid, :not_integer_in_1_to_9}
  end
  defp check_valid_move(session, n)  do
    %__MODULE__{board: {crosses, noughts}} = session
    if n in crosses or n in noughts do
      {:invalid, :move_to_occupied_square}
    else
      :valid
    end
  end

  defp check_for_end(player, board) do
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

  defp next_player(:crosses), do: :noughts
  defp next_player(:noughts), do: :crosses

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
