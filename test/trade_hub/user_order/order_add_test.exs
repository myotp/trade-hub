defmodule TradeHub.UserOrder.OrderAddTest do
  use TradeHub.DataCase
  alias TradeHub.UserOrder.OrderAdd
  alias TradeHub.Db.StockDb

  setup do
    old_mod = Application.get_env(:trade_hub, :user_order_db_mod)
    Application.put_env(:trade_hub, :user_order_db_mod, TradeHub.Db.UserOrderDb)
    StockDb.create_stock("AAPL")

    on_exit(fn ->
      Application.put_env(:trade_hub, :user_order_db_mod, old_mod)
    end)
  end

  describe "create_buy_order" do
    test "successfully create order and save to db" do
      OrderAdd.create_buy_order("AAPL", 1001, 500, 100)
    end
  end
end
