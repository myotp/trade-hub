defmodule TradeHub.Repo.Migrations.CreateStocksTable do
  use Ecto.Migration

  def change do
    create table(:stocks) do
      add :symbol, :text, null: false
    end

    create unique_index(:stocks, [:symbol])

    execute "ALTER SEQUENCE stocks_id_seq RESTART WITH 60001;"
  end
end
