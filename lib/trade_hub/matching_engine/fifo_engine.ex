defmodule TradeHub.MatchingEngine.FifoEngine do
  alias TradeHub.MatchingEngine.FifoEngine, as: Engine

  @moduledoc """
  FifoEngine - 按照Price/Time Priority执行FIFO式matching engine

  这里，MinimumOrder定义matching engine所需的最必需的信息
  并且, 每个instrument有自己的matching engine此处不再需要对应的instrument-id了
  在返回executed当中，记录所有执行了matching的订单
  对于partially executed订单，这里可以更新剩余数量
  对于partially executed订单，应该把priority调到同价格最高才合理
  对于执行的订单，或者部分执行的订单，交由上一层记录总量，剩余量等，并且通知客户端
  """
  defmodule MinimumOrder do
    defstruct [
      :order_id,
      :side,
      :price,
      :quantity,
      # 这里通常是时间顺序
      :priority
    ]
  end

  defstruct [
    :buys,
    :sells,
    :executed
  ]

  # API
  def new() do
    %__MODULE__{
      buys: [],
      sells: [],
      executed: []
    }
  end

  def add_order(engine, order) do
    min_order = create_minimum_order(order)
    add_minimum_order(engine, min_order)
  end

  defp create_minimum_order(%{
         order_id: order_id,
         side: side,
         price: price,
         quantity: quantity,
         priority: priority
       }) do
    %MinimumOrder{
      order_id: order_id,
      side: side,
      price: price,
      quantity: quantity,
      priority: priority
    }
  end

  defp add_minimum_order(engine, %MinimumOrder{} = min_order) do
    engine = %Engine{engine | executed: []}

    case matching_order(engine, min_order) do
      {updated_engine, nil} ->
        updated_engine

      {updated_engine, order_left} ->
        add_passive_order(updated_engine, order_left)
    end
  end

  defp matching_order(%Engine{sells: []} = engine, %MinimumOrder{side: :BUY} = order) do
    {engine, order}
  end

  defp matching_order(%Engine{buys: []} = engine, %MinimumOrder{side: :SELL} = order) do
    {engine, order}
  end

  defp matching_order(
         %Engine{sells: [%MinimumOrder{price: sell_price} | _]} = engine,
         %MinimumOrder{side: :BUY, price: buy_price} = order
       )
       when buy_price < sell_price do
    {engine, order}
  end

  defp matching_order(
         %Engine{buys: [%MinimumOrder{price: buy_price} | _]} = engine,
         %MinimumOrder{side: :SELL, price: sell_price} = order
       )
       when buy_price < sell_price do
    {engine, order}
  end

  # handle new BUY order
  defp matching_order(
         %Engine{
           sells: [
             %MinimumOrder{price: sell_price, quantity: sell_quantity} = first_sell | rest_sells
           ],
           executed: executed_acc
         } = engine,
         %MinimumOrder{side: :BUY, price: buy_price, quantity: buy_quantity} = buy_order
       )
       when buy_price >= sell_price do
    cond do
      buy_quantity == sell_quantity ->
        new_executed = [first_sell, %MinimumOrder{buy_order | price: sell_price} | executed_acc]
        {%Engine{engine | sells: rest_sells, executed: new_executed}, nil}

      buy_quantity > sell_quantity ->
        new_executed = [
          first_sell,
          %MinimumOrder{buy_order | price: sell_price, quantity: sell_quantity} | executed_acc
        ]

        buy_order_left = %MinimumOrder{buy_order | quantity: buy_order.quantity - sell_quantity}

        matching_order(
          %Engine{engine | sells: rest_sells, executed: new_executed},
          buy_order_left
        )

      buy_quantity < sell_quantity ->
        new_executed = [
          %MinimumOrder{first_sell | quantity: buy_quantity},
          %MinimumOrder{buy_order | price: sell_price, quantity: buy_quantity} | executed_acc
        ]

        first_sell_left = %MinimumOrder{first_sell | quantity: first_sell.quantity - buy_quantity}
        {%Engine{engine | sells: [first_sell_left | rest_sells], executed: new_executed}, nil}
    end
  end

  # handle new SELL order
  defp matching_order(
         %Engine{
           buys: [
             %MinimumOrder{price: buy_price, quantity: buy_quantity} = first_buy | rest_buys
           ],
           executed: executed_acc
         } = engine,
         %MinimumOrder{side: :SELL, price: sell_price, quantity: sell_quantity} = sell_order
       )
       when buy_price >= sell_price do
    cond do
      sell_quantity == buy_quantity ->
        new_executed = [first_buy, %MinimumOrder{sell_order | price: buy_price} | executed_acc]
        {%Engine{engine | buys: rest_buys, executed: new_executed}, nil}

      sell_quantity > buy_quantity ->
        new_executed = [
          first_buy,
          %MinimumOrder{sell_order | price: buy_price, quantity: buy_quantity} | executed_acc
        ]

        sell_order_left = %MinimumOrder{sell_order | quantity: sell_order.quantity - buy_quantity}

        matching_order(
          %Engine{engine | buys: rest_buys, executed: new_executed},
          sell_order_left
        )

      sell_quantity < buy_quantity ->
        new_executed = [
          %MinimumOrder{first_buy | quantity: sell_quantity},
          %MinimumOrder{sell_order | price: buy_price, quantity: sell_quantity} | executed_acc
        ]

        first_buy_left = %MinimumOrder{first_buy | quantity: first_buy.quantity - sell_quantity}
        {%Engine{engine | buys: [first_buy_left | rest_buys], executed: new_executed}, nil}
    end
  end

  defp add_passive_order(%Engine{buys: buys} = engine, %MinimumOrder{side: :BUY} = order) do
    new_buys = sort_passive_orders([order | buys])
    %__MODULE__{engine | buys: new_buys}
  end

  defp add_passive_order(%Engine{sells: sells} = engine, %MinimumOrder{side: :SELL} = order) do
    new_sells = sort_passive_orders([order | sells])
    %__MODULE__{engine | sells: new_sells}
  end

  defp sort_passive_orders(orders) do
    Enum.sort_by(orders, &price_time_priority/1)
  end

  defp price_time_priority(%{price: price, priority: priority, side: :BUY}) do
    # Buy orders are sorted in descending order
    {-price, priority}
  end

  defp price_time_priority(%{price: price, priority: priority, side: :SELL}) do
    {price, priority}
  end
end
