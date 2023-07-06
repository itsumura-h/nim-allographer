import std/os
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/query_interface
import ../enums
import ./sub/migration_table_def
import ./sub/create_query_def


proc alter*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")

  # create migration table
  var query = createQuery(rdb, migrationTable)
  query.createMigrationTable()

  for i, table in tables:
    table.usecaseType = Alter
    case table.migrationType
    of CreateTable:
      for column in table.columns:
        column.usecaseType = Alter 
        case column.migrationType
        of AddColumn:
          query = createQuery(rdb, table, column)
          query.addColumn(isReset)
        of ChangeColumn:
          query = createQuery(rdb, table, column)
          query.changeColumn(isReset)
        of RenameColumn:
          query = createQuery(rdb, table, column)
          query.renameColumn(isReset)
        of DropColumn:
          query = createQuery(rdb, table, column)
          query.dropColumn(isReset)
    of ChangeTable:
      discard
    of RenameTable:
      discard
    of DropTable:
      query = createQuery(rdb, table)
      query.dropTable(isReset)
