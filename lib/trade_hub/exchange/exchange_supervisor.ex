defmodule TradeHub.Exchange.ExchangeSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      {Registry, [keys: :unique, name: TradeHub.Exchange.StockRegistry]},
      TradeHub.Exchange.StockServerManager
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
