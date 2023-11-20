defmodule TradeHub.MatchingEngine do
  alias TradeHub.MatchingEngine.FifoEngine

  def new() do
    FifoEngine.new()
  end

  def add_order(engine, order) do
    FifoEngine.add_order(engine, order)
  end
end
