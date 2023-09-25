import std/os
import ../../../env
import ../../../query_builder/models/postgres/postgres_types
import ../../models/table
import ../../models/column
import ../../enums
import ../sub/migration_table_def
import ./create_query_def


proc alter*(rdb:PostgresConnections, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createSchema(rdb, migrationTable)
  query.createMigrationTable()

  for i, table in tables:
    table.usecaseType = Alter
    case table.migrationType
    of CreateTable:
      for column in table.columns:
        column.usecaseType = Alter 
        case column.migrationType
        of AddColumn:
          discard
          query = createSchema(rdb, table, column)
          query.addColumn(isReset)
        of ChangeColumn:
          discard
          query = createSchema(rdb, table, column)
          query.changeColumn(isReset)
        of RenameColumn:
          discard
          query = createSchema(rdb, table, column)
          query.renameColumn(isReset)
        of DropColumn:
          discard
          query = createSchema(rdb, table, column)
          query.dropColumn(isReset)
    of ChangeTable:
      discard
    of RenameTable:
      query = createSchema(rdb, table)
      query.renameTable(isReset)
    of DropTable:
      discard
