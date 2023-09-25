import ../../queries/schema_interface
import ../../../query_builder/models/sqlite/sqlite_types
import ../../queries/sqlite/sqlite_query_type
import ../../queries/sqlite/sqlite_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:SqliteConnections, table:Table):ISchema =
  return SqliteSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:SqliteConnections, table:Table, column:Column):ISchema =
  return SqliteSchema.new(rdb, table, column).toInterface()
