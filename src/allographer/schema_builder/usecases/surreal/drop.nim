import std/os
import ../../../query_builder/models/surreal/surreal_types
import ../../models/table
import ../../enums
import ../sub/migration_table_def
import ./create_query_def
import ../../queries/surreal/create_migration_table
import ../../queries/surreal/drop_table


proc drop*(rdb:SurrealConnections, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createSchema(rdb, migrationTable)
  query.createMigrationTable()

  for table in tables:
    table.usecaseType = Drop
    query = createSchema(rdb, table)
    query.dropTable(isReset)
