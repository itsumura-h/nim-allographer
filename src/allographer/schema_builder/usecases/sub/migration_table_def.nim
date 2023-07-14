import ../../models/table
import ../../models/column

let migrationTable* :Table = table("_migrations", [
  Column.increments("id"),
  Column.string("name"),
  Column.text("query"),
  Column.string("checksum").index(),
  Column.datetime("created_at").index(),
  Column.boolean("status")
])


let surrealMigrationTable* :Table = table("_migrations", [
  Column.uuid("id"),
  Column.string("name"),
  Column.text("query"),
  Column.string("checksum").index(),
  Column.datetime("created_at").index(),
  Column.boolean("status")
])
