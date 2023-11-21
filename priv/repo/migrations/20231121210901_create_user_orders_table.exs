defmodule TradeHub.Repo.Migrations.CreateUserOrdersTable do
  use Ecto.Migration

  def change do
    create table(:user_orders, primary_key: false) do
      add :order_id, :bigserial, primary_key: true
      # TODO: references
      add :stock_symbol, :text, null: false
      # TODO: references
      add :client_id, :bigint, null: false
      add :side, :integer, null: false
      add :price, :bigint, null: false
      add :quantity, :bigint, null: false
      add :leaves_quantity, :bigint, null: false
      add :priority, :bigint, null: false
      add :type, :integer, null: false
      add :status, :integer, null: false

      timestamps()
    end

    create index(:user_orders, [:client_id])

    execute "ALTER SEQUENCE user_orders_order_id_seq RESTART WITH 9990001;"
  end
end
