# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TradeHub.Repo.insert!(%TradeHub.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TradeHub.Db.StockDb
alias TradeHub.Db.StockPriceDb

{:ok, _} = StockDb.create_stock("DEV1")
{:ok, _} = StockDb.create_stock("DEV2")
{:ok, _} = StockDb.create_stock("DEV3")

StockPriceDb.save_stock_closing_price("DEV1", ~D[1999-12-28], 300)
StockPriceDb.save_stock_closing_price("DEV1", ~D[1999-12-29], 500)
StockPriceDb.save_stock_closing_price("DEV1", ~D[1999-12-31], 800)
