defmodule TradeHub.MatchingEngine.FifoEngineTest do
  use ExUnit.Case
  alias TradeHub.MatchingEngine.FifoEngine

  test "new/0" do
    assert FifoEngine.new() == %FifoEngine{buys: [], sells: [], executed: []}
  end

  describe "add_order/2" do
    test "An order will be added to passive order list if it can't match" do
      buy_order = %{order_id: 1001, side: :BUY, price: 100, quantity: 20, priority: 500}
      engine = FifoEngine.new()

      assert %FifoEngine{
               buys: [%FifoEngine.MinimumOrder{order_id: 1001}],
               sells: [],
               executed: []
             } = FifoEngine.add_order(engine, buy_order)
    end
  end

  describe "price-time priority" do
    test "Buy orders are executed based on best (highest) price" do
      buy1 = %{order_id: "price1", side: :BUY, price: 100, quantity: 20, priority: 500}
      buy2 = %{order_id: "price2", side: :BUY, price: 110, quantity: 20, priority: 500}
      buy3 = %{order_id: "price3", side: :BUY, price: 125, quantity: 20, priority: 500}
      buy4 = %{order_id: "price4", side: :BUY, price: 200, quantity: 20, priority: 500}
      buy5 = %{order_id: "price5", side: :BUY, price: 350, quantity: 20, priority: 500}

      engine =
        [buy1, buy2, buy3, buy4, buy5]
        |> Enum.shuffle()
        |> Enum.reduce(FifoEngine.new(), fn order, engine_acc ->
          FifoEngine.add_order(engine_acc, order)
        end)

      assert %FifoEngine{
               buys: [
                 %FifoEngine.MinimumOrder{order_id: "price5"},
                 %FifoEngine.MinimumOrder{order_id: "price4"},
                 %FifoEngine.MinimumOrder{order_id: "price3"},
                 %FifoEngine.MinimumOrder{order_id: "price2"},
                 %FifoEngine.MinimumOrder{order_id: "price1"}
               ],
               sells: [],
               executed: []
             } = engine
    end

    test "Eearlier time buy orders first" do
      buy1 = %{order_id: "time1", side: :BUY, price: 100, quantity: 20, priority: 480}
      buy2 = %{order_id: "time2", side: :BUY, price: 100, quantity: 20, priority: 499}
      buy3 = %{order_id: "time3", side: :BUY, price: 100, quantity: 20, priority: 502}
      buy4 = %{order_id: "time4", side: :BUY, price: 100, quantity: 20, priority: 510}
      buy5 = %{order_id: "time5", side: :BUY, price: 100, quantity: 20, priority: 530}

      engine =
        [buy1, buy2, buy3, buy4, buy5]
        |> Enum.shuffle()
        |> Enum.reduce(FifoEngine.new(), fn order, engine_acc ->
          FifoEngine.add_order(engine_acc, order)
        end)

      assert %FifoEngine{
               buys: [
                 %FifoEngine.MinimumOrder{order_id: "time1"},
                 %FifoEngine.MinimumOrder{order_id: "time2"},
                 %FifoEngine.MinimumOrder{order_id: "time3"},
                 %FifoEngine.MinimumOrder{order_id: "time4"},
                 %FifoEngine.MinimumOrder{order_id: "time5"}
               ],
               sells: [],
               executed: []
             } = engine
    end

    test "Buy orders are executed based on best (highest) price, if multiple orders are at the same price, an order with an earlier time trades first" do
      buy1 = %{order_id: "10", side: :BUY, price: 100, quantity: 20, priority: 100}
      buy2 = %{order_id: "11", side: :BUY, price: 220, quantity: 20, priority: 220}
      buy3 = %{order_id: "12", side: :BUY, price: 100, quantity: 20, priority: 300}
      buy4 = %{order_id: "13", side: :BUY, price: 100, quantity: 20, priority: 280}
      buy5 = %{order_id: "15", side: :BUY, price: 220, quantity: 20, priority: 100}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(buy1)
        |> FifoEngine.add_order(buy2)
        |> FifoEngine.add_order(buy3)
        |> FifoEngine.add_order(buy4)
        |> FifoEngine.add_order(buy5)

      assert %FifoEngine{
               buys: [
                 %FifoEngine.MinimumOrder{order_id: "15"},
                 %FifoEngine.MinimumOrder{order_id: "11"},
                 %FifoEngine.MinimumOrder{order_id: "10"},
                 %FifoEngine.MinimumOrder{order_id: "13"},
                 %FifoEngine.MinimumOrder{order_id: "12"}
               ],
               sells: [],
               executed: []
             } = engine
    end

    test "Sell orders are executed based on best (lowest) price" do
      sell1 = %{order_id: "price1", side: :SELL, price: 100, quantity: 20, priority: 500}
      sell2 = %{order_id: "price2", side: :SELL, price: 110, quantity: 20, priority: 500}
      sell3 = %{order_id: "price3", side: :SELL, price: 125, quantity: 20, priority: 500}
      sell4 = %{order_id: "price4", side: :SELL, price: 200, quantity: 20, priority: 500}
      sell5 = %{order_id: "price5", side: :SELL, price: 350, quantity: 20, priority: 500}

      engine =
        [sell1, sell2, sell3, sell4, sell5]
        |> Enum.shuffle()
        |> Enum.reduce(FifoEngine.new(), fn order, engine_acc ->
          FifoEngine.add_order(engine_acc, order)
        end)

      assert %FifoEngine{
               buys: [],
               sells: [
                 %FifoEngine.MinimumOrder{order_id: "price1"},
                 %FifoEngine.MinimumOrder{order_id: "price2"},
                 %FifoEngine.MinimumOrder{order_id: "price3"},
                 %FifoEngine.MinimumOrder{order_id: "price4"},
                 %FifoEngine.MinimumOrder{order_id: "price5"}
               ],
               executed: []
             } = engine
    end

    test "Eearlier time sell orders first" do
      sell1 = %{order_id: "time1", side: :SELL, price: 100, quantity: 20, priority: 480}
      sell2 = %{order_id: "time2", side: :SELL, price: 100, quantity: 20, priority: 499}
      sell3 = %{order_id: "time3", side: :SELL, price: 100, quantity: 20, priority: 502}
      sell4 = %{order_id: "time4", side: :SELL, price: 100, quantity: 20, priority: 510}
      sell5 = %{order_id: "time5", side: :SELL, price: 100, quantity: 20, priority: 530}

      engine =
        [sell1, sell2, sell3, sell4, sell5]
        |> Enum.shuffle()
        |> Enum.reduce(FifoEngine.new(), fn order, engine_acc ->
          FifoEngine.add_order(engine_acc, order)
        end)

      assert %FifoEngine{
               buys: [],
               sells: [
                 %FifoEngine.MinimumOrder{order_id: "time1"},
                 %FifoEngine.MinimumOrder{order_id: "time2"},
                 %FifoEngine.MinimumOrder{order_id: "time3"},
                 %FifoEngine.MinimumOrder{order_id: "time4"},
                 %FifoEngine.MinimumOrder{order_id: "time5"}
               ],
               executed: []
             } = engine
    end

    test "Sell orders are executed based on best (lowest) price, if multiple orders are at the same price, an order with an earlier time trades first" do
      sell1 = %{order_id: "10", side: :SELL, price: 100, quantity: 20, priority: 100}
      sell2 = %{order_id: "11", side: :SELL, price: 220, quantity: 20, priority: 220}
      sell3 = %{order_id: "12", side: :SELL, price: 100, quantity: 20, priority: 300}
      sell4 = %{order_id: "13", side: :SELL, price: 100, quantity: 20, priority: 280}
      sell5 = %{order_id: "15", side: :SELL, price: 220, quantity: 20, priority: 100}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(sell1)
        |> FifoEngine.add_order(sell2)
        |> FifoEngine.add_order(sell3)
        |> FifoEngine.add_order(sell4)
        |> FifoEngine.add_order(sell5)

      assert %FifoEngine{
               buys: [],
               sells: [
                 %FifoEngine.MinimumOrder{order_id: "10"},
                 %FifoEngine.MinimumOrder{order_id: "13"},
                 %FifoEngine.MinimumOrder{order_id: "12"},
                 %FifoEngine.MinimumOrder{order_id: "15"},
                 %FifoEngine.MinimumOrder{order_id: "11"}
               ],
               executed: []
             } = engine
    end
  end

  describe "matching-order to execute buy order" do
    test "an order can't match will be added to passive orders" do
      passive_sell_order = %{order_id: 1001, side: :SELL, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_sell_order)

      buy_order = %{
        order_id: 1002,
        side: :BUY,
        price: 98,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{
               buys: [%FifoEngine.MinimumOrder{order_id: 1002}],
               sells: [%FifoEngine.MinimumOrder{order_id: 1001}],
               executed: []
             } =
               FifoEngine.add_order(engine, buy_order)
    end

    test "matching order will execute order with a match" do
      passive_sell_order = %{order_id: 1001, side: :SELL, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_sell_order)

      aggressive_buy_order = %{
        order_id: 1002,
        side: :BUY,
        price: 99,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, aggressive_buy_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end

    test "matching order might match multiple passive orders" do
      sell_order1 = %{order_id: 1001, side: :SELL, price: 99, quantity: 20, priority: 500}
      sell_order2 = %{order_id: 1002, side: :SELL, price: 99, quantity: 30, priority: 502}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(sell_order1)
        |> FifoEngine.add_order(sell_order2)

      aggressive_buy_order = %{
        order_id: 1003,
        side: :BUY,
        price: 99,
        quantity: 50,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, aggressive_buy_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99, quantity: 30}
               | partially_executed_orders
             ] = Enum.sort_by(executed, & &1.order_id)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1003, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1003, price: 99, quantity: 30}
             ] = Enum.sort_by(partially_executed_orders, & &1.quantity)
    end

    test "limit order executed at a better price" do
      passive_sell_order = %{order_id: 1001, side: :SELL, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_sell_order)

      aggressive_buy_order = %{
        order_id: 1002,
        side: :BUY,
        price: 200,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, aggressive_buy_order)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end

    test "price might be different in partially executed orders" do
      sell1 = %{order_id: 1001, side: :SELL, price: 99, quantity: 20, priority: 500}
      sell2 = %{order_id: 1002, side: :SELL, price: 103, quantity: 30, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(sell1)
        |> FifoEngine.add_order(sell2)

      aggressive_buy_order = %{
        order_id: 1003,
        side: :BUY,
        price: 200,
        quantity: 50,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, aggressive_buy_order)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 103} | partially_executed_orders
             ] =
               Enum.sort_by(executed, & &1.order_id)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1003, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1003, price: 103, quantity: 30}
             ] = Enum.sort_by(partially_executed_orders, & &1.quantity)
    end

    test "new order might be partially executed" do
      sell_order = %{order_id: 1001, side: :SELL, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(sell_order)

      aggressive_buy_order = %{
        order_id: 1002,
        side: :BUY,
        price: 200,
        quantity: 100,
        priority: 500
      }

      assert %FifoEngine{
               buys: [%FifoEngine.MinimumOrder{order_id: 1002, price: 200, quantity: 80}],
               sells: [],
               executed: executed
             } =
               FifoEngine.add_order(engine, aggressive_buy_order)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99, quantity: 20}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end

    test "passive orders might be partially executed" do
      sell_order = %{order_id: 1001, side: :SELL, price: 99, quantity: 40, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(sell_order)

      aggressive_buy_order = %{
        order_id: 1002,
        side: :BUY,
        price: 200,
        quantity: 10,
        priority: 500
      }

      assert %FifoEngine{
               buys: [],
               sells: [%FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 30}],
               executed: executed
             } =
               FifoEngine.add_order(engine, aggressive_buy_order)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 10},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99, quantity: 10}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end
  end

  describe "matching-order to execute sell order" do
    test "an order can't match will be added to passive orders" do
      passive_buy_order = %{order_id: 1001, side: :BUY, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_buy_order)

      sell_order = %{
        order_id: 1002,
        side: :SELL,
        price: 105,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{
               buys: [%FifoEngine.MinimumOrder{order_id: 1001}],
               sells: [%FifoEngine.MinimumOrder{order_id: 1002}],
               executed: []
             } =
               FifoEngine.add_order(engine, sell_order)
    end

    test "matching order will execute order with a match" do
      passive_buy_order = %{order_id: 1001, side: :BUY, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_buy_order)

      sell_order = %{
        order_id: 1002,
        side: :SELL,
        price: 99,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, sell_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end

    test "matching order might match multiple passive orders" do
      buy1 = %{order_id: 1001, side: :BUY, price: 99, quantity: 20, priority: 500}
      buy2 = %{order_id: 1002, side: :BUY, price: 99, quantity: 30, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(buy1)
        |> FifoEngine.add_order(buy2)

      sell_order = %{
        order_id: 1003,
        side: :SELL,
        price: 99,
        quantity: 50,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, sell_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99} | partially_executed_orders
             ] =
               Enum.sort_by(executed, & &1.order_id)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1003, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1003, price: 99, quantity: 30}
             ] = Enum.sort_by(partially_executed_orders, & &1.quantity)
    end

    test "limit order executed at a better price" do
      passive_buy_order = %{order_id: 1001, side: :BUY, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_buy_order)

      sell_order = %{
        order_id: 1002,
        side: :SELL,
        price: 88,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, sell_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end

    test "price might be different in partially executed orders" do
      buy1 = %{order_id: 1001, side: :BUY, price: 99, quantity: 20, priority: 500}
      buy2 = %{order_id: 1002, side: :BUY, price: 95, quantity: 30, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(buy1)
        |> FifoEngine.add_order(buy2)

      sell_order = %{
        order_id: 1003,
        side: :SELL,
        price: 90,
        quantity: 50,
        priority: 500
      }

      assert %FifoEngine{buys: [], sells: [], executed: executed} =
               FifoEngine.add_order(engine, sell_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 95} | partially_executed_orders
             ] =
               Enum.sort_by(executed, & &1.order_id)

      assert [
               %FifoEngine.MinimumOrder{order_id: 1003, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1003, price: 95, quantity: 30}
             ] = Enum.sort_by(partially_executed_orders, & &1.quantity)
    end

    test "new order might be partially executed" do
      passive_buy_order = %{order_id: 1001, side: :BUY, price: 99, quantity: 20, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_buy_order)

      sell_order = %{
        order_id: 1002,
        side: :SELL,
        price: 90,
        quantity: 50,
        priority: 500
      }

      assert %FifoEngine{
               buys: [],
               sells: [%FifoEngine.MinimumOrder{order_id: 1002, price: 90, quantity: 30}],
               executed: executed
             } =
               FifoEngine.add_order(engine, sell_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99, quantity: 20}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end

    test "passive orders might be partially executed" do
      passive_buy_order = %{order_id: 1001, side: :BUY, price: 99, quantity: 50, priority: 500}

      engine =
        FifoEngine.new()
        |> FifoEngine.add_order(passive_buy_order)

      sell_order = %{
        order_id: 1002,
        side: :SELL,
        price: 90,
        quantity: 20,
        priority: 500
      }

      assert %FifoEngine{
               buys: [%FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 30}],
               sells: [],
               executed: executed
             } =
               FifoEngine.add_order(engine, sell_order)

      assert executed != []

      assert [
               %FifoEngine.MinimumOrder{order_id: 1001, price: 99, quantity: 20},
               %FifoEngine.MinimumOrder{order_id: 1002, price: 99, quantity: 20}
             ] =
               Enum.sort_by(executed, & &1.order_id)
    end
  end
end
