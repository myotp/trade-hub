defmodule TradeHub.OrderPersist.UserOrderDbTest do
  use TradeHub.DataCase
  alias TradeHub.OrderPersist.UserOrderDb

  describe "save_user_order/1" do
    test "successfully write user order to DB" do
      user_order = %{
        side: :BUY,
        stock_symbol: "AAPL",
        client_id: 1001,
        price: 508,
        quantity: 100,
        leaves_quantity: 100,
        priority: 99999,
        type: :LIMITED
      }

      assert {:ok, order_from_db} =
               UserOrderDb.save_order_and_get_order_id(user_order)
               |> IO.inspect(label: "USER ORDER RESULT")
    end
  end
end
