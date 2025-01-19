import std/os
import ../../../query_builder/models/surreal/surreal_types
import ../../models/table
import ../../models/column
import ../../enums
import ../sub/migration_table_def
import ./create_query_def
import ../../queries/surreal/create_migration_table
import ../../queries/surreal/add_column
import ../../queries/surreal/change_column
import ../../queries/surreal/rename_column
import ../../queries/surreal/drop_column
import ../../queries/surreal/rename_table


proc alter*(rdb:SurrealConnections, tables:varargs[Table]) =
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
          query = createSchema(rdb, table, column)
          query.addColumn(isReset)
        of ChangeColumn:
          query = createSchema(rdb, table, column)
          query.changeColumn(isReset)
        of RenameColumn:
          query = createSchema(rdb, table, column)
          query.renameColumn(isReset)
        of DropColumn:
          query = createSchema(rdb, table, column)
          query.dropColumn(isReset)
    of ChangeTable:
      discard
    of RenameTable:
      query = createSchema(rdb, table)
      query.renameTable(isReset)
    of DropTable:
      discard
