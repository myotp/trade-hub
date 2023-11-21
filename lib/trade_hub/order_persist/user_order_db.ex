defmodule TradeHub.OrderPersist.UserOrderDb do
  use Ecto.Schema
  import Ecto.Changeset
  alias TradeHub.Repo

  @primary_key false
  schema "user_orders" do
    field :order_id, :id, primary_key: true
    field :side, Ecto.Enum, values: [SELL: 31, BUY: 32]
    field :stock_symbol, :string
    field :client_id, :id
    field :price, :integer
    field :quantity, :integer
    field :leaves_quantity, :integer
    field :priority, :integer
    field :type, Ecto.Enum, values: [LIMITED: 21]
    field :status, Ecto.Enum, values: [CREATED: 51, CANCELLED: 52], default: :CREATED

    timestamps()
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields)
  end

  def changeset(user_order \\ %__MODULE__{}, attrs) do
    user_order
    |> cast(attrs, all_fields())
  end

  @callback save_order_and_get_order_id(struct() | map()) :: {:ok, integer()}
  def save_order_and_get_order_id(user_order) when is_struct(user_order) do
    user_order
    |> Map.from_struct()
    |> save_order_and_get_order_id()
  end

  def save_order_and_get_order_id(user_order) do
    {:ok, order} =
      user_order
      |> changeset()
      |> Repo.insert(returning: [:order_id])

    IO.inspect(label: "ORDER FROM DB")
    {:ok, order.order_id}
  end
end
