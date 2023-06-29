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
# import ../queries/postgres/postgres_query_type
# import ../queries/postgres/postgres_query_impl
# import ../queries/mysql/mysql_query
# import ../queries/query_interface


proc create*(rdb:Rdb, tables:varargs[Table]) =
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
  # create table
  # var query =
  #   case rdb.driver
  #   of SQLite3:
  #     SqliteQuery.new(rdb, migrationTable).toInterface()
  #   of PostgreSQL:
  #     PostgresQuery.new(rdb, migrationTable).toInterface()
  #   else:
  #     SqliteQuery.new(rdb, migrationTable).toInterface()

  var query = SqliteQuery.new(rdb, migrationTable).toInterface()
  query.createMigrationTable()

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      # query =
      #   case rdb.driver
      #   of SQLite3:
      #     SqliteQuery.new(rdb, table).toInterface()
      #   of PostgreSQL:
      #     PostgresQuery.new(rdb, table).toInterface()
      #   else:
      #     SqliteQuery.new(rdb, table).toInterface()
      query = SqliteQuery.new(rdb, table).toInterface()
      query.resetMigrationTable()
      query.resetTable()

  for table in tables:
    # query =
    #   case rdb.driver
    #   of SQLite3:
    #     SqliteQuery.new(rdb, table).toInterface()
    #   of PostgreSQL:
    #     PostgresQuery.new(rdb, table).toInterface()
    #   else:
    #     SqliteQuery.new(rdb, table).toInterface()
    table.usecaseType = Create
    query = SqliteQuery.new(rdb, table).toInterface()
    query.createTable(isReset)
