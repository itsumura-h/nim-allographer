import std/os
import ../enums
import ../../query_builder/rdb/rdb_types
import ../../query_builder/surreal/surreal_types
import ../models/table
import ./sub/migration_table_def
import ./sub/create_query_def


proc create*(rdb:Rdb | SurrealDb, tables:varargs[Table]) =
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
