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
      Column.integer("created_at").index(),
      Column.integer("updated_at").index(),
    ]),
    table("post", [
      Column.uuid("id").index(),
      Column.string("title"),
      Column.string("content"),
      Column.strForeign("user_id").reference("id").onTable("user"),
      Column.integer("created_at").index(),
      Column.integer("updated_at").index(),
    ])
  ])
