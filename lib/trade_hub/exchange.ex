defmodule TradeHub.Exchange do
  alias TradeHub.Exchange.StockServer

  def get_current_price(stock_symbol) do
    StockServer.current_price(stock_symbol)
  end
end
