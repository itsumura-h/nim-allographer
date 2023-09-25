import std/os
import ../../../env
import ../../../query_builder/models/postgres/postgres_types
import ../../models/table
import ../../enums
import ../sub/migration_table_def
import ./create_query_def


proc drop*(rdb:PostgresConnections, tables:varargs[Table]) =
  when isExistsPostgres:
    let cmd = commandLineParams()
    let isReset = defined(reset) or cmd.contains("--reset")

    # create migration table
    var query = createSchema(rdb, migrationTable)
    query.createMigrationTable()

    for table in tables:
      table.usecaseType = Drop
      query = createSchema(rdb, table)
      query.dropTable(isReset)
