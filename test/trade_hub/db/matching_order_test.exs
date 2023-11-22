defmodule TradeHub.Db.MatchingOrderTest do
  use TradeHub.DataCase
  alias TradeHub.Db.MatchingOrder

  describe "save_order/1" do
    test "successfully write matching order to DB" do
      matching_order = %{order_id: 1001, side: :BUY, price: 508, quantity: 100, priority: 99999}

      assert {:ok, order_from_db} =
               MatchingOrder.save_order(matching_order)

      assert Repo.get!(MatchingOrder, order_from_db.id).price == 508
    end
  end
end
