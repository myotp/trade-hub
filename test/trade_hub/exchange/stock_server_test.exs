defmodule TradeHub.Exchange.StockServerTest do
  use ExUnit.Case

  alias TradeHub.Exchange.StockServer
  alias TradeHub.UserOrder.OrderAdd

  import Hammox
  setup :set_mox_global
  setup :verify_on_exit!

  describe "current_price/1" do
    test "get closing price" do
      assert {:ok, _pid} =
               start_supervised(
                 {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 500}},
                 restart: :temporary
               )

      assert {:ok, 500} = StockServer.current_price("AAPL")
    end
  end

  describe "add_order/2" do
    test "ACCEPTED: new order will be added to passive orders if there is no matches" do
      MockUserOrderDb
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 999_001} end)

      {:ok, _pid} =
        start_supervised(
          {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 500}},
          restart: :temporary
        )

      order = OrderAdd.create_buy_order("AAPL", 1001, 500, 100)
      assert {:ok, :ACCEPTED} = StockServer.add_order("AAPL", order)
    end

    test "TRADED: new order might be executed immediately if there is matching order" do
      MockUserOrderDb
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 999_001} end)
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 999_002} end)

      {:ok, _pid} =
        start_supervised(
          {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 499}},
          restart: :temporary
        )

      sell_order = OrderAdd.create_sell_order("AAPL", 1001, 500, 100)
      {:ok, :ACCEPTED} = StockServer.add_order("AAPL", sell_order)
      assert {:ok, 499} == StockServer.current_price("AAPL")

      buy_order = OrderAdd.create_buy_order("AAPL", 1001, 500, 100)
      assert {:ok, :TRADED} = StockServer.add_order("AAPL", buy_order)
      assert {:ok, 500} == StockServer.current_price("AAPL")
    end

    test "MATCHING: new order might be partially executed if there is not enough matching orders" do
      MockUserOrderDb
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 999_001} end)
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 999_002} end)

      {:ok, _pid} =
        start_supervised(
          {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 505}},
          restart: :temporary
        )

      sell_order = OrderAdd.create_sell_order("AAPL", 1001, 500, 20)
      {:ok, :ACCEPTED} = StockServer.add_order("AAPL", sell_order)

      buy_order = OrderAdd.create_buy_order("AAPL", 1002, 500, 50)
      assert {:ok, :MATCHING} = StockServer.add_order("AAPL", buy_order)
    end

    test "multiply buy and sell orders" do
      MockUserOrderDb
      |> expect(:save_order_and_get_order_id, 4, fn _ ->
        {:ok, System.unique_integer([:positive, :monotonic])}
      end)

      {:ok, _pid} =
        start_supervised(
          {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 505}},
          restart: :temporary
        )

      # price will not change if there is no matching orders
      sell_order = OrderAdd.create_sell_order("AAPL", 1001, 502, 20)
      {:ok, :ACCEPTED} = StockServer.add_order("AAPL", sell_order)
      assert {:ok, 505} == StockServer.current_price("AAPL")

      # matching-order will change the price
      buy_order = OrderAdd.create_buy_order("AAPL", 1002, 508, 50)
      assert {:ok, :MATCHING} = StockServer.add_order("AAPL", buy_order)
      assert {:ok, 502} == StockServer.current_price("AAPL")

      # another buy order will become passive order
      buy_order2 = OrderAdd.create_buy_order("AAPL", 1003, 498, 40)
      {:ok, :ACCEPTED} = StockServer.add_order("AAPL", buy_order2)
      assert {:ok, 502} == StockServer.current_price("AAPL")

      # 50 -20 + 40 = 70
      sell_order2 = OrderAdd.create_sell_order("AAPL", 1004, 485, 70)
      {:ok, :TRADED} = StockServer.add_order("AAPL", sell_order2)
      assert {:ok, 498} == StockServer.current_price("AAPL")
    end

    test "publish matching orders and updated user orders" do
      MockUserOrderDb
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 8001} end)
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 8002} end)
      |> expect(:save_order_and_get_order_id, fn _ -> {:ok, 8003} end)

      Phoenix.PubSub.subscribe(TradeHub.PubSub, "matching_order_executed")
      Phoenix.PubSub.subscribe(TradeHub.PubSub, "user_order_changed")

      {:ok, _pid} =
        start_supervised(
          {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 505}},
          restart: :temporary
        )

      sell1 = OrderAdd.create_sell_order("AAPL", 1001, 500, 60)
      {:ok, :ACCEPTED} = StockServer.add_order("AAPL", sell1)
      sell2 = OrderAdd.create_sell_order("AAPL", 1002, 498, 50)
      {:ok, :ACCEPTED} = StockServer.add_order("AAPL", sell2)

      buy_order = OrderAdd.create_buy_order("AAPL", 1003, 510, 70)
      {:ok, :TRADED} = StockServer.add_order("AAPL", buy_order)

      # 3 user orders changed
      assert_receive [_, _, _] = updated_user_orders

      assert [
               %OrderAdd{
                 order_id: 8001,
                 quantity: 60,
                 leaves_quantity: 40
               },
               %OrderAdd{
                 order_id: 8002,
                 quantity: 50,
                 leaves_quantity: 0
               },
               %OrderAdd{
                 order_id: 8003,
                 quantity: 70,
                 leaves_quantity: 0
               }
             ] = updated_user_orders |> Enum.sort_by(& &1.order_id)

      # 4 matching orders executed
      assert_receive executed_matching_orders
      assert Enum.count(executed_matching_orders) == 4

      assert [{8002, 498, 50}, {8003, 498, 50}, {8001, 500, 20}, {8003, 500, 20}] |> Enum.sort() ==
               Enum.map(executed_matching_orders, &{&1.order_id, &1.price, &1.quantity})
               |> Enum.sort()
    end
  end
end
