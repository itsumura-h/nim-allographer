import std/os
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../queries/query_interface
import ../enums
import ./sub/migration_table_def
import ./sub/create_query_def


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
