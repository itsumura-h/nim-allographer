import ../../models/table
import ../../models/column

let migrationTable* :Table = table("allographer_migrations", [
  Column.increments("id"),
  Column.string("name"),
  Column.text("query"),
  Column.string("checksum").index(),
  Column.datetime("created_at").index(),
  Column.boolean("status")
])
