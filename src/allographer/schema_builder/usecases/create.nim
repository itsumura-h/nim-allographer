import std/os
import std/json
import std/options
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/sqlite/sqlite_query
import ../queries/postgres/postgres_query
import ../queries/mysql/mysql_query
import ../queries/query_interface


proc create*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  let generator =
    case rdb.driver
    of SQLite3:
      SqliteQuery.new(rdb).toInterface()
    of PostgreSQL:
      PostgresQuery.new(rdb).toInterface()
    of MySQL, MariaDB:
      MysqlQuery.new(rdb).toInterface()

  # let generator = SqliteQuery.new(rdb).toInterface()
  # let generator = PostgresQuery.new(rdb).toInterface()

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

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      generator.resetMigrationTable(table)
      generator.resetTable(table)

  for table in tables:
    # Search migration history by table name and create it if not found.
    let history = generator.getHistories(table)
    if history.len == 0 or isReset:
      generator.createTableSql(table)
      generator.execThenSaveHistory(table.name, table.query, table.checksum)
