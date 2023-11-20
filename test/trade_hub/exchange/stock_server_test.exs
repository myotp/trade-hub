defmodule TradeHub.Exchange.StockServerTest do
  use ExUnit.Case

  alias TradeHub.Exchange.StockServer
  alias TradeHub.UserOrder.OrderAdd

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
      {:ok, _pid} =
        start_supervised(
          {StockServer, %{stock_id: 100, stock_symbol: "AAPL", current_price: 500}},
          restart: :temporary
        )

      order = OrderAdd.create_buy_order("AAPL", 1001, 500, 100)
      assert {:ok, :ACCEPTED} = StockServer.add_order("AAPL", order)
    end

    test "TRADED: new order might be executed immediately if there is matching order" do
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
  end
end
