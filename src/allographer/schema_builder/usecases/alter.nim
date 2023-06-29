import std/os
import std/json
import std/strutils
import std/sha1
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/query_interface
import ../queries/sqlite/sqlite_query_type
import ../queries/sqlite/sqlite_query_impl
# import ../queries/postgres/postgres_query_type
# import ../queries/postgres/postgres_query_impl
import ../enums


proc alter*(rdb:Rdb, tables:varargs[Table]) =
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
  # var query = PostgresQuery.new(rdb, migrationTable).toInterface()
  query.createMigrationTable()

  for i, table in tables:
    table.usecaseType = Alter
    case table.migrationType
    of CreateTable:
      for column in table.columns:
        column.usecaseType = Alter 
        case column.migrationType
        of AddColumn:
          query = SqliteQuery.new(rdb, table, column).toInterface()
          query.addColumn(isReset)
        of ChangeColumn:
          query = SqliteQuery.new(rdb, table, column).toInterface()
          query.changeColumn(isReset)
        of RenameColumn:
          query = SqliteQuery.new(rdb, table, column).toInterface()
          query.renameColumn(isReset)
        of DeleteColumn:
          query = SqliteQuery.new(rdb, table, column).toInterface()
          query.deleteColumn(isReset)
    of ChangeTable:
      discard
    of RenameTable:
      discard
    of DropTable:
      query = SqliteQuery.new(rdb, table).toInterface()
      query.dropTable(isReset)
