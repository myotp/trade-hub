defmodule TradeHub.Db.StockDbTest do
  use TradeHub.DataCase
  alias TradeHub.Db.StockDb
  alias TradeHub.Db.StockPriceDb

  describe "create_stock/1" do
    test "successfully write stock DB" do
      assert {:ok, _} = StockDb.create_stock("AAPL")
    end

    test "fail to create stock with duplicate symbol" do
      assert {:ok, _} = StockDb.create_stock("AAPL")
      assert {:error, _} = StockDb.create_stock("AAPL")
    end
  end

  describe "load_stock_with_closing_price/1" do
    test "successfully return stock with closing price" do
      assert {:ok, _} = StockDb.create_stock("AAPL")
      StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-13], 800)

      stock_from_db =
        StockDb.load_stock_with_closing_price("AAPL")

      assert stock_from_db.symbol == "AAPL"
      assert stock_from_db.closing_price == 800
    end

    test "stock without closing price" do
      assert {:ok, _} = StockDb.create_stock("AAPL")

      stock_from_db =
        StockDb.load_stock_with_closing_price("AAPL")

      assert stock_from_db.symbol == "AAPL"
      assert stock_from_db.closing_price == nil
    end

    test "stock is not found" do
      assert nil == StockDb.load_stock_with_closing_price("AAPL")
    end
  end

  describe "all_stocks" do
    test "successfully return all stocks and closing price" do
      {:ok, _} = StockDb.create_stock("A1")
      assert [%StockDb{symbol: "A1", closing_price: nil}] = StockDb.all_stocks()

      {:ok, _} = StockDb.create_stock("A2")
      StockPriceDb.save_stock_closing_price("A2", ~D[2023-11-13], 100)

      assert [
               %StockDb{symbol: "A1", closing_price: nil},
               %StockDb{symbol: "A2", closing_price: 100}
             ] = StockDb.all_stocks()
    end
  end
end
