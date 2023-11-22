defmodule TradeHub.Repo.Migrations.CreateStockPricesTable do
  use Ecto.Migration

  def change do
    create table(:stock_prices) do
      add :stock_symbol,
          references(:stocks, column: :symbol, type: :text),
          null: false

      add :trading_date, :date
      add :closing_price, :bigint, null: false
    end

    create unique_index(:stock_prices, [:stock_symbol, :trading_date])
  end
end
