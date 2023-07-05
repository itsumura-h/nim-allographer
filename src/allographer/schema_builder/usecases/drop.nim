import std/os
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/query_interface
import ../queries/sqlite/sqlite_query_type
import ../queries/sqlite/sqlite_query_impl
import ../queries/postgres/postgres_query_type
import ../queries/postgres/postgres_query_impl
import ../enums
import ./sub/migration_table_def


proc createQuery(rdb:Rdb, table:Table):IQuery =
  case rdb.driver
  of SQLite3:
    return SqliteQuery.new(rdb, table).toInterface()
  of PostgreSQL:
    return PostgresQuery.new(rdb, table).toInterface()
  else:
    return SqliteQuery.new(rdb, table).toInterface()


proc drop*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createQuery(rdb, migrationTable)
  query.createMigrationTable()

  for table in tables:
    table.usecaseType = Drop
    query = createQuery(rdb, table)
    query.dropTable(isReset)
