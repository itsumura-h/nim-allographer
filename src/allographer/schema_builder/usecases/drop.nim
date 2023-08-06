import std/os
import ../../query_builder/models/sqlite/sqlite_types
import ../../query_builder/models/postgres/postgres_types
# import ../../query_builder/surreal/surreal_types
import ../models/table
import ../enums
import ./sub/migration_table_def
import ./sub/create_query_def


proc drop*(rdb:SqliteConnections, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createSchema(rdb, migrationTable)
  query.createMigrationTable()

  for table in tables:
    table.usecaseType = Drop
    query = createSchema(rdb, table)
    query.dropTable(isReset)


proc drop*(rdb:PostgresConnections, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createSchema(rdb, migrationTable)
  query.createMigrationTable()

  for table in tables:
    table.usecaseType = Drop
    query = createSchema(rdb, table)
    query.dropTable(isReset)
