import ../../../query_builder/models/sqlite/sqlite_types
import ../../models/table
import ../../models/column

type SqliteSchema* = ref object
  rdb*:SqliteConnections
  table*:Table
  column*:Column

proc new*(_:type SqliteSchema, rdb:SqliteConnections, table:Table):SqliteSchema =
  return SqliteSchema(rdb:rdb, table:table)

proc new*(_:type SqliteSchema, rdb:SqliteConnections, table:Table, column:Column):SqliteSchema =
  return SqliteSchema(rdb:rdb, table:table, column:column)
