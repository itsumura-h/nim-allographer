import std/os
import ../../enums
import ../../../query_builder/models/mysql/mysql_types
import ../../models/table
import ../sub/migration_table_def
import ./create_query_def
import ../../queries/mysql/create_migration_table
import ../../queries/mysql/create_table
import ../../queries/mysql/reset_table


proc create*(rdb:MysqlConnections, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createSchema(rdb, migrationTable)
  query.createMigrationTable()

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      query = createSchema(rdb, table)
      query.resetMigrationTable()
      query.resetTable()

  for table in tables:
    table.usecaseType = Create
    query = createSchema(rdb, table)
    query.createTable(isReset)
