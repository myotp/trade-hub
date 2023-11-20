defmodule TradeHub.UserOrder.OrderAdd do
  defstruct [
    :order_id,
    :stock_symbol,
    :client_id,
    :price,
    :quantity,
    :leaves_quantity,
    :priority,
    :side,
    type: :LIMITED
  ]

  def create_buy_order(symbol, client_id, price, quantity, order_id \\ nil) do
    do_create_order(symbol, client_id, :BUY, price, quantity, order_id)
  end

  def create_sell_order(symbol, client_id, price, quantity, order_id \\ nil) do
    do_create_order(symbol, client_id, :SELL, price, quantity, order_id)
  end

  defp do_create_order(symbol, client_id, side, price, quantity, order_id) do
    %__MODULE__{
      order_id: order_id || unique_order_id(),
      stock_symbol: symbol,
      client_id: client_id,
      side: side,
      price: price,
      quantity: quantity,
      leaves_quantity: quantity,
      priority: generate_priority(),
      type: :LIMITED
    }
  end

  defp generate_priority() do
    {seconds, milliseconds} =
      NaiveDateTime.utc_now(:millisecond) |> NaiveDateTime.to_gregorian_seconds()

    seconds * 100 + div(milliseconds, 10000)
  end

  defp unique_order_id() do
    System.unique_integer([:positive, :monotonic])
  end
end
