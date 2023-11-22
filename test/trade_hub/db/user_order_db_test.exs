defmodule TradeHub.Db.UserOrderDbTest do
  use TradeHub.DataCase
  alias TradeHub.Db.UserOrderDb
  alias TradeHub.Db.StockDb

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

      {:ok, _} = StockDb.create_stock("AAPL")

      assert {:ok, order_id} =
               UserOrderDb.save_order_and_get_order_id(user_order)

      assert is_integer(order_id)
    end
  end
end
