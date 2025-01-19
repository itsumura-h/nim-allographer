import ../../../query_builder/models/surreal/surreal_types
import ../../queries/surreal/surreal_query_type
import ../../models/table
import ../../models/column


proc createSchema*(rdb:SurrealConnections, table:Table):SurrealSchema =
  return SurrealSchema.new(rdb, table)

proc createSchema*(rdb:SurrealConnections, table:Table, column:Column):SurrealSchema =
  return SurrealSchema.new(rdb, table, column)
