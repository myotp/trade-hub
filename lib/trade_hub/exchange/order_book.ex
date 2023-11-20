defmodule TradeHub.Exchange.OrderBook do
  def new() do
    %{}
  end

  def add_order(order_book, buy_or_sell_order) do
    Map.put(order_book, buy_or_sell_order.order_id, buy_or_sell_order)
  end

  def get_order(order_book, order_id) do
    order_book[order_id]
  end

  def run_executed(order_book, executed) do
    {updated_order_book, updated_order_ids} =
      update_leaves_quantity(order_book, executed, MapSet.new())

    {updated_order_book, Enum.map(updated_order_ids, &get_order(updated_order_book, &1))}
  end

  def update_leaves_quantity(order_book, [], order_ids) do
    {order_book, order_ids}
  end

  def update_leaves_quantity(order_book, [order | rest], order_ids) do
    order_ids = MapSet.put(order_ids, order.order_id)
    full_order = Map.fetch!(order_book, order.order_id)
    full_order = %{full_order | leaves_quantity: full_order.leaves_quantity - order.quantity}
    update_leaves_quantity(Map.put(order_book, order.order_id, full_order), rest, order_ids)
  end
end
