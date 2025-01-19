import ../../../query_builder/models/sqlite/sqlite_types
import ../../queries/sqlite/sqlite_query_type
import ../../models/table
import ../../models/column


proc createSchema*(rdb:SqliteConnections, table:Table):SqliteSchema =
  return SqliteSchema.new(rdb, table)

proc createSchema*(rdb:SqliteConnections, table:Table, column:Column):SqliteSchema =
  return SqliteSchema.new(rdb, table, column)
