defmodule TradeHub.Exchange.StockServerStarter do
  use GenServer, restart: :transient
  require Logger
  alias TradeHub.Db.StockDb
  alias TradeHub.Exchange.StockServerManager

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl GenServer
  def init(_) do
    {:ok, [], {:continue, :start_stock_processes}}
  end

  @impl GenServer
  def handle_continue(:start_stock_processes, state) do
    StockDb.all_stocks()
    |> Enum.each(&start_stock_child/1)

    {:stop, {:shutdown, :start_stocks_job_done}, state}
  end

  defp start_stock_child(%StockDb{id: stock_id, symbol: symbol, closing_price: closing_price}) do
    {:ok, pid} =
      StockServerManager.start_stock_server(%{
        stock_id: stock_id,
        stock_symbol: symbol,
        current_price: closing_price
      })

    Logger.info("#{symbol} #{inspect(pid)} started")
  end

  # 这里，针对transient类型，shutdown加原因的话，算正常关闭，不log，不重启
  @impl GenServer
  def terminate({:shutdown, :start_stocks_job_done}, _state) do
    Logger.info("#{inspect(self())} 结束启动股票进程工作，现在结束")
    :ok
  end
end
