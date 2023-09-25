import std/os
import ../../../env
import ../../enums
import ../../../query_builder/models/surreal/surreal_types
import ../../queries/surreal/create_sequence_table
import ../../models/table
import ../sub/migration_table_def
import ./create_query_def


proc create*(rdb:SurrealConnections, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createSchema(rdb, migrationTable)
  createSequenceTable(rdb)
  resetSequence(rdb, Table(name:"_allographer_migrations"))
  query.createMigrationTable()

  if isReset:
    # delete table in reverse loop in tables
    for i in countdown(tables.len-1, 0):
      let table = tables[i]
      resetSequence(rdb, table)
      query = createSchema(rdb, table)
      query.resetMigrationTable()
      query.resetTable()

  for table in tables:
    table.usecaseType = Create
    query = createSchema(rdb, table)
    query.createTable(isReset)
