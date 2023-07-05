import std/os
import std/json
import std/options
import ../enums
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/query_interface
import ../queries/sqlite/sqlite_query_type
import ../queries/sqlite/sqlite_query_impl
import ../queries/postgres/postgres_query_type
import ../queries/postgres/postgres_query_impl
# import ../queries/mysql/mysql_query
# import ../queries/query_interface
import ./sub/migration_table_def


proc createQuery(rdb:Rdb, table:Table):IQuery =
  case rdb.driver
  of SQLite3:
    return SqliteQuery.new(rdb, table).toInterface()
  of PostgreSQL:
    return PostgresQuery.new(rdb, table).toInterface()
  else:
    return SqliteQuery.new(rdb, table).toInterface()


proc create*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createQuery(rdb, migrationTable)
  query.createMigrationTable()

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      query = createQuery(rdb, table)
      query.resetMigrationTable()
      query.resetTable()

  for table in tables:
    table.usecaseType = Create
    query = createQuery(rdb, table)
    query.createTable(isReset)
