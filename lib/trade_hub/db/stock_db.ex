defmodule TradeHub.Db.StockDb do
  use Ecto.Schema
  import Ecto.Changeset
  alias TradeHub.Repo
  alias TradeHub.Db.StockPriceDb

  schema "stocks" do
    field :symbol, :string
    field :closing_price, :integer, virtual: true
  end

  def changeset(stock \\ %__MODULE__{}, attrs) do
    stock
    |> cast(attrs, [:symbol])
    |> unique_constraint(:symbol)
  end

  def create_stock(symbol) when is_binary(symbol) do
    create_stock(%{symbol: symbol})
  end

  def create_stock(attrs) do
    attrs
    |> changeset()
    |> Repo.insert()
  end

  def load_stock_with_closing_price(symbol) do
    case Repo.get_by(__MODULE__, symbol: symbol) do
      nil ->
        nil

      stock_from_db ->
        add_closing_price(stock_from_db)
    end
  end

  defp add_closing_price(stock) do
    last_closing_price = StockPriceDb.get_last_closing_price(stock.symbol)
    %__MODULE__{stock | closing_price: last_closing_price}
  end

  def all_stocks() do
    Repo.all(__MODULE__)
    |> Enum.map(&add_closing_price/1)
  end
end
