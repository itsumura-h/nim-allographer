import std/os
import ../../query_builder/models/sqlite/sqlite_types
import ../../query_builder/models/postgres/postgres_types
import ../../query_builder/models/mariadb/mariadb_types
import ../../query_builder/models/surreal/surreal_types
import ../models/table
import ../models/column
import ../enums
import ./sub/migration_table_def
import ./sub/create_query_def


proc alter*(rdb:SqliteConnections, tables:varargs[Table]) =
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


proc alter*(rdb:MariadbConnections, tables:varargs[Table]) =
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
