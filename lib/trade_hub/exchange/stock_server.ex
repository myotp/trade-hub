defmodule TradeHub.Exchange.StockServer do
  use GenServer
  require Logger

  alias TradeHub.Exchange.OrderBook
  alias TradeHub.MatchingEngine

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

  def add_order(stock_symbol, user_order) do
    stock_symbol
    |> via_symbol_tuple()
    |> GenServer.call({:add_order, user_order})
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
       matching_engine: MatchingEngine.new(),
       order_book: OrderBook.new()
     }}
  end

  @impl GenServer
  def handle_call(:current_price, _from, %State{current_price: current_price} = state) do
    {:reply, {:ok, current_price}, state}
  end

  def handle_call(
        {:add_order, new_order},
        _from,
        %State{order_book: order_book, matching_engine: matching_engine} = state
      ) do
    order_book = OrderBook.add_order(order_book, new_order)
    matching_engine = MatchingEngine.add_order(matching_engine, new_order)

    case matching_engine.executed do
      [] ->
        {:reply, {:ok, :ACCEPTED},
         %State{state | order_book: order_book, matching_engine: matching_engine}}

      executed ->
        # TODO: Publish updated orders
        {updated_order_book, updated_user_orders} = OrderBook.run_executed(order_book, executed)
        price = last_price(executed, new_order.side)

        user_order_status =
          current_user_order_status_after_matching(updated_user_orders, new_order.order_id)

        {:reply, {:ok, user_order_status},
         %State{
           state
           | matching_engine: matching_engine,
             order_book: updated_order_book,
             current_price: price
         }}
    end
  end

  defp current_user_order_status_after_matching(updated_orders, order_id) do
    user_order = Enum.find(updated_orders, &(&1.order_id == order_id))

    case user_order.leaves_quantity do
      0 ->
        :TRADED

      _ ->
        :MATCHING
    end
  end

  defp last_price(executed, side) do
    sort_order =
      case side do
        :BUY -> :desc
        :SELL -> :asc
      end

    executed
    |> Enum.map(& &1.price)
    |> Enum.sort(sort_order)
    |> hd()
  end
end
