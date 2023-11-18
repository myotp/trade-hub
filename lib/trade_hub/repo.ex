defmodule TradeHub.Repo do
  use Ecto.Repo,
    otp_app: :trade_hub,
    adapter: Ecto.Adapters.Postgres
end
