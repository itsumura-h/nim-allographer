import std/os
import std/json
import std/options
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/query_interface
import ../queries/sqlite/sqlite_query_type
import ../queries/sqlite/sqlite_query_impl
import ../enums


proc drop*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  let migrationTable = table("_migrations", [
    Column.string("name"),
    Column.text("query"),
    Column.string("checksum").index(),
    Column.datetime("created_at").index(),
    Column.boolean("status")
  ])
  var query = SqliteQuery.new(rdb, migrationTable).toInterface()
  query.createMigrationTable()

  for table in tables:
    table.usecaseType = Drop
    query = SqliteQuery.new(rdb, table).toInterface()
    query.dropTable(isReset)
