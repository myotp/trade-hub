defmodule TradeHub.Exchange.OrderBookTest do
  use ExUnit.Case
  alias TradeHub.Exchange.OrderBook

  describe "execute/2" do
    test "update leaves quantity for partially executed order" do
      {order_book, _changing_orders} =
        OrderBook.new()
        |> OrderBook.add_order(%{order_id: 1001, quantity: 50, leaves_quantity: 50})
        |> OrderBook.run_executed([%{order_id: 1001, quantity: 20}])

      assert %{quantity: 50, leaves_quantity: 30} = OrderBook.get_order(order_book, 1001)
    end

    test "update leaves quantity for multiple executed orders" do
      {order_book, _changing_orders} =
        OrderBook.new()
        |> OrderBook.add_order(%{order_id: 1001, quantity: 50, leaves_quantity: 50})
        |> OrderBook.run_executed([
          %{order_id: 1001, quantity: 20},
          %{order_id: 1001, quantity: 18}
        ])

      assert %{quantity: 50, leaves_quantity: 12} = OrderBook.get_order(order_book, 1001)
    end
  end
end
