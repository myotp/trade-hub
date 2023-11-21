defmodule TradeHub.Repo.Migrations.CreateMatchingOrdersTable do
  use Ecto.Migration

  def change do
    create table(:matching_orders) do
      add :order_id, :bigint, null: false
      add :side, :integer, null: false
      add :price, :bigint, null: false
      add :quantity, :bigint, null: false

      timestamps(updated_at: false)
    end

    create index(:matching_orders, [:order_id])
  end
end
