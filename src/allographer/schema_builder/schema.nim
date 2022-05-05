import os, json, options
import ../base
import ../async/async_db
import ../query_builder
import ./grammers
import ./queries/query_interface
import ./queries/sqlite/sqlite_query
import ./queries/mysql/mysql_query
import ./queries/postgre/postgre_query


proc create*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")
  echo rdb.driver
  let generator =
    case rdb.driver
    of SQLite3:
      SqliteQuery.new(rdb).toInterface()
    of MySQL, MariaDB:
      MysqlQuery.new(rdb).toInterface()
    of PostgreSQL:
      PostgreQuery.new(rdb).toInterface()
    else:
      SqliteQuery.new(rdb).toInterface()

  # migration table
  let migrationTable = table("allographer_migrations", [
    Column.increments("id"),
    Column.string("name"),
    Column.text("query"),
    Column.string("checksum").index(),
    Column.datetime("created_at"),
    Column.boolean("status")
  ])
  generator.createTableSql(migrationTable)
  generator.runQuery(migrationTable.query)

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      generator.resetTable(table)

  for table in tables:
    let history = generator.getHistories(table)
    # not exists history || reset => create table
    if history.len == 0 or isReset:
      generator.createTableSql(table)
      generator.runQueryThenSaveHistory(table.name, table.query, table.checksum)


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
  let generator =
    case rdb.driver
    of SQLite3:
      SqliteQuery.new(rdb).toInterface()
    of MySQL, MariaDB:
      MysqlQuery.new(rdb).toInterface()
    of PostgreSQL:
      PostgreQuery.new(rdb).toInterface()
    else:
      SqliteQuery.new(rdb).toInterface()

  for i, table in tables:
    # カラム変更
    case table.migrationType
    of CreateTable:
      for column in table.columns:
        let history = generator.getHistories(table)
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
    of RenameTable:
      generator.renameTableSql(table)
      let history = generator.getHistories(table)
      if shouldRunProcess(history, table.checksum, isReset):
        generator.renameTable(table)
    of DropTable:
      generator.dropTableSql(table)
      let history = generator.getHistories(table)
      if shouldRunProcess(history, table.checksum, isReset):
        generator.dropTable(table)
    else:
      discard
