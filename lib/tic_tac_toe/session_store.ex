defmodule TicTacToe.SessionStore do
  require Logger

  @store_name :game_sessions

  def new() do
    :ets.new(@store_name, [:public,
                           :named_table,
                           :set,
                           {:write_concurrency, true}])
  end

  def init_session(nil, _session), do: :ok
  def init_session(game, session) do
    :ets.insert(@store_name, {game, session})
  end

  def get_session(nil), do: :no_session
  def get_session(game) do
    case :ets.lookup(@store_name, game) do
      [{^game, session}] ->
        session
      [] ->
        :no_session
    end
  end

  def update_session(nil, _session), do: :ok
  def update_session(game, session) do
    :ets.update_element(@store_name, game, {2, session})
  end

  def delete_session(nil), do: :ok
  def delete_session(game) do
    :ets.delete(@store_name, game)
  end
end
