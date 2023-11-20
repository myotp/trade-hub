defmodule TradeHub.Exchange.StockServerManager do
  use DynamicSupervisor

  # API
  def start_stock_server(args) do
    DynamicSupervisor.start_child(__MODULE__, {TradeHub.Exchange.StockServer, args})
  end

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
