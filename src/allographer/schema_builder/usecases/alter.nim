import std/os
import ../../query_builder/rdb/rdb_types
import ../../query_builder/surreal/surreal_types
import ../models/table
import ../models/column
import ../enums
import ./sub/migration_table_def
import ./sub/create_query_def


proc alter*(rdb:Rdb | SurrealDb, tables:varargs[Table]) =
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
          discard
          query = createQuery(rdb, table, column)
          query.addColumn(isReset)
        of ChangeColumn:
          discard
          query = createQuery(rdb, table, column)
          query.changeColumn(isReset)
        of RenameColumn:
          discard
          query = createQuery(rdb, table, column)
          query.renameColumn(isReset)
        of DropColumn:
          discard
          query = createQuery(rdb, table, column)
          query.dropColumn(isReset)
    of ChangeTable:
      discard
    of RenameTable:
      discard
    of DropTable:
      discard
