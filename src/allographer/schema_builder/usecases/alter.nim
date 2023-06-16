import std/os
import std/json
import std/strutils
import std/sha1
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/sqlite/sqlite_query
# import ../queries/postgres/postgres_query
# import ../queries/mysql/mysql_query
import ../enums
import ../queries/query_interface


proc shouldRunProcess(history:JsonNode, checksum:string, isReset:bool):bool =
  if isReset:
    return true
  if not history.contains(checksum):
    return true
  if not history[checksum]["status"].getBool:
    return true
  return false


proc alter*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # let generator =
  #   case rdb.driver
  #   of SQLite3:
  #     SqliteQuery.new(rdb).toInterface()
  #   of PostgreSQL:
  #     PostgresQuery.new(rdb).toInterface()
  #   of MySQL, MariaDB:
  #     MysqlQuery.new(rdb).toInterface()
  let generator = SqliteQuery.new(rdb).toInterface()

  # create migration table
  let migrationTable = table("_migrations", [
    Column.string("name"),
    Column.text("query"),
    Column.string("checksum").index(),
    Column.datetime("created_at"),
    Column.boolean("status")
  ])
  # create table
  generator.createTableSql(migrationTable)
  generator.exec(migrationTable)

  for i, table in tables:
    let history = generator.getHistories(table)
    case table.migrationType
    of CreateTable:
      for column in table.columns:
        case column.migrationType
        of AddColumn:
          generator.addColumnSql(column, table)
          if shouldRunProcess(history, column.checksum, isReset):
            generator.addColumn(column, table)
        of ChangeColumn:
          generator.changeColumnSql(column, table)
          if shouldRunProcess(history, column.checksum, isReset):
            generator.changeColumn(column, table)
        of RenameColumn:
          generator.renameColumnSql(column, table)
          if shouldRunProcess(history, column.checksum, isReset):
            generator.renameColumn(column, table)
        of DeleteColumn:
          generator.deleteColumnSql(column, table)
          if shouldRunProcess(history, column.checksum, isReset):
            generator.deleteColumn(column, table)
    of ChangeTable:
      discard
    of RenameTable:
      discard
    of DropTable:
      discard
