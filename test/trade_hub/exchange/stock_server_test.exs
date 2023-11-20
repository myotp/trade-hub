defmodule TradeHub.Exchange.StockServerTest do
  use ExUnit.Case

  alias TradeHub.Exchange.StockServer

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
end
