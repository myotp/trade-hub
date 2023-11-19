defmodule TradeHub.MatchingEngine.FifoEngine do
  alias TradeHub.MatchingEngine.FifoEngine, as: Engine
  # MinimumOrder定义matching engine所需的最必需的信息
  # 并且, 每个instrument有自己的matching engine此处不再需要对应的instrument-id了
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
    case matching_order(engine, min_order) do
      {^engine, min_order, []} ->
        add_passive_order(%Engine{engine | executed: []}, min_order)
    end
  end

  defp matching_order(engine, order) do
    {engine, order, []}
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
