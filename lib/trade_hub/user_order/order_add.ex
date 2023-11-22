defmodule TradeHub.UserOrder.OrderAdd do
  defstruct [
    :order_id,
    :side,
    :stock_symbol,
    :client_id,
    :price,
    :quantity,
    :leaves_quantity,
    :priority,
    type: :LIMITED
  ]

  def create_buy_order(symbol, client_id, price, quantity) do
    do_create_order(symbol, client_id, :BUY, price, quantity)
  end

  def create_sell_order(symbol, client_id, price, quantity) do
    do_create_order(symbol, client_id, :SELL, price, quantity)
  end

  defp do_create_order(symbol, client_id, side, price, quantity) do
    args =
      %__MODULE__{
        stock_symbol: symbol,
        client_id: client_id,
        side: side,
        price: price,
        quantity: quantity,
        leaves_quantity: quantity,
        priority: generate_priority(),
        type: :LIMITED
      }

    {:ok, order_id} = user_order_db_mod().save_order_and_get_order_id(args)
    %__MODULE__{args | order_id: order_id}
  end

  defp generate_priority() do
    {seconds, milliseconds} =
      NaiveDateTime.utc_now(:millisecond) |> NaiveDateTime.to_gregorian_seconds()

    seconds * 100 + div(milliseconds, 10000)
  end

  defp user_order_db_mod() do
    Application.get_env(:trade_hub, :user_order_db_mod, TradeHub.Db.UserOrderDb)
  end
end
