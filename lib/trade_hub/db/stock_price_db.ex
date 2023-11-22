defmodule TradeHub.Db.StockPriceDb do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias TradeHub.Repo

  schema "stock_prices" do
    field :stock_symbol, :string
    field :trading_date, :date
    field :closing_price, :integer
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields)
  end

  def get_last_closing_price(stock_symbol) do
    query =
      from sp in __MODULE__,
        where: sp.stock_symbol == ^stock_symbol,
        order_by: [desc: :trading_date],
        limit: 1,
        select: [:closing_price]

    case Repo.all(query) do
      [sp] ->
        sp.closing_price

      [] ->
        nil
    end
  end

  def save_stock_closing_price(stock_symbol, trading_date, closing_price) do
    %{stock_symbol: stock_symbol, trading_date: trading_date, closing_price: closing_price}
    |> save_stock_closing_price()
  end

  defp save_stock_closing_price(attrs) do
    attrs
    |> changeset()
    |> Repo.insert(
      conflict_target: [:stock_symbol, :trading_date],
      on_conflict: {:replace_all_except, [:id]}
    )
  end

  def changeset(stock_prices \\ %__MODULE__{}, attrs) do
    stock_prices
    |> cast(attrs, all_fields())
  end
end
