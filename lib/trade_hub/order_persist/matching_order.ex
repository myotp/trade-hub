defmodule TradeHub.OrderPersist.MatchingOrder do
  use Ecto.Schema
  import Ecto.Changeset
  alias TradeHub.Repo

  schema "matching_orders" do
    field :order_id, :id
    field :side, Ecto.Enum, values: [SELL: 31, BUY: 32]
    field :price, :integer
    field :quantity, :integer

    timestamps(updated_at: false)
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields)
  end

  def changeset(matching_order \\ %__MODULE__{}, attrs) do
    matching_order
    |> cast(attrs, all_fields())
  end

  def save_order(matching_order) do
    matching_order
    |> changeset()
    |> Repo.insert(returning: [:id])
  end
end
