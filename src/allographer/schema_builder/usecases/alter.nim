import std/os
import ../../query_builder/rdb/rdb_types
import ../models/table
import ../models/column
import ../queries/query_interface
import ../queries/sqlite/sqlite_query_type
import ../queries/sqlite/sqlite_query_impl
import ../queries/postgres/postgres_query_type
import ../queries/postgres/postgres_query_impl
import ../enums
import ./sub/migration_table_def


proc createQuery(rdb:Rdb, table:Table):IQuery =
  case rdb.driver
  of SQLite3:
    return SqliteQuery.new(rdb, table).toInterface()
  of PostgreSQL:
    return PostgresQuery.new(rdb, table).toInterface()
  else:
    return SqliteQuery.new(rdb, table).toInterface()


proc createQuery(rdb:Rdb, table:Table, column:Column):IQuery =
  case rdb.driver
  of SQLite3:
    return SqliteQuery.new(rdb, table, column).toInterface()
  of PostgreSQL:
    return PostgresQuery.new(rdb, table, column).toInterface()
  else:
    return SqliteQuery.new(rdb, table, column).toInterface()


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
        of DeleteColumn:
          query = createQuery(rdb, table, column)
          query.deleteColumn(isReset)
    of ChangeTable:
      discard
    of RenameTable:
      discard
    of DropTable:
      query = createQuery(rdb, table)
      query.dropTable(isReset)
