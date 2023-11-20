defmodule TradeHub.Exchange.StockServer do
  use GenServer
  require Logger

  alias TradeHub.MatchingEngine.FifoEngine

  defmodule State do
    defstruct [
      :stock_id,
      :stock_symbol,
      :current_price,
      :matching_engine,
      :order_book
    ]
  end

  # API
  def current_price(stock_symbol) do
    stock_symbol
    |> via_symbol_tuple()
    |> GenServer.call(:current_price)
  end

  def whereis(stock_symbol) do
    stock_symbol
    |> via_symbol_tuple()
    |> GenServer.whereis()
  end

  # GenServer
  def start_link(%{stock_symbol: stock_symbol} = arg) do
    GenServer.start_link(__MODULE__, arg, name: via_symbol_tuple(stock_symbol))
  end

  defp via_symbol_tuple(symbol) do
    {:via, Registry, {TradeHub.Exchange.StockRegistry, symbol}}
  end

  # GenServer
  @impl GenServer
  def init(%{stock_id: stock_id, stock_symbol: stock_symbol, current_price: price}) do
    {:ok,
     %State{
       stock_id: stock_id,
       stock_symbol: stock_symbol,
       current_price: price,
       matching_engine: FifoEngine.new(),
       order_book: nil
     }}
  end

  @impl GenServer
  def handle_call(:current_price, _from, %State{current_price: current_price} = state) do
    {:reply, {:ok, current_price}, state}
  end
end
