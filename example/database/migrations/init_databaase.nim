import ../../../src/allographer/schema_builder
import ../connection

proc init_databaase*() =
  ## 0001
  rdb.create([
    table("user", [
      Column.uuid("id").index(),
      Column.string("name"),
      Column.string("email"),
      Column.string("password"),
      Column.timestamps(),
    ]),
    table("post", [
      Column.uuid("id").index(),
      Column.string("title"),
      Column.string("content"),
      Column.strForeign("user_id").reference("id").onTable("user"),
      Column.timestamps(),
    ])
  ])
