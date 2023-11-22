defmodule TradeHub.Db.StockPriceDbTest do
  use TradeHub.DataCase
  alias TradeHub.Db.StockDb
  alias TradeHub.Db.StockPriceDb

  setup do
    {:ok, _} = StockDb.create_stock("AAPL")
    {:ok, _} = StockDb.create_stock("BEST")
    :ok
  end

  describe "save_stock_closing_price/3" do
    test "successfully save stock closing prices to DB" do
      {:ok, result} = StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-11], 500_800)
      assert %{closing_price: 500_800} = Repo.get(StockPriceDb, result.id)
    end

    test "latest inserted value replaces the existing one for entries with the same symbol and date." do
      {:ok, aapl} = StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-11], 11)
      assert %{closing_price: 11} = Repo.get(StockPriceDb, aapl.id)
      {:ok, best} = StockPriceDb.save_stock_closing_price("BEST", ~D[2023-11-11], 201)
      assert %{closing_price: 201} = Repo.get(StockPriceDb, best.id)

      {:ok, _} = StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-11], 12)
      assert %{closing_price: 12} = Repo.get(StockPriceDb, aapl.id)
      assert %{closing_price: 201} = Repo.get(StockPriceDb, best.id)
    end
  end

  describe "get_last_closing_price/1" do
    test "successfully get last closing price" do
      {:ok, _} = StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-11], 1111)
      {:ok, _} = StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-13], 3333)
      {:ok, _} = StockPriceDb.save_stock_closing_price("AAPL", ~D[2023-11-12], 2222)

      assert 3333 == StockPriceDb.get_last_closing_price("AAPL")
    end

    test "no closing prices" do
      assert nil == StockPriceDb.get_last_closing_price("NEW")
    end
  end
end
