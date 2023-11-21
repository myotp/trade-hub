defmodule TradeHub.UserOrder.OrderAddTest do
  use TradeHub.DataCase
  alias TradeHub.UserOrder.OrderAdd

  setup do
    old_mod = Application.get_env(:trade_hub, :user_order_persist_mod)
    Application.put_env(:trade_hub, :user_order_persist_mod, TradeHub.OrderPersist.UserOrderDb)

    on_exit(fn ->
      Application.put_env(:trade_hub, :user_order_persist_mod, old_mod)
    end)
  end

  describe "create_buy_order" do
    test "successfully create order and save to db" do
      OrderAdd.create_buy_order("AAPL", 1001, 500, 100)
    end
  end
end
