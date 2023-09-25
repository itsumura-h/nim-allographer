import ../../../query_builder/models/surreal/surreal_types
import ../../models/table
import ../../models/column


type SurrealSchema* = ref object
  rdb*:SurrealConnections
  table*:Table
  column*:Column

proc new*(_:type SurrealSchema, rdb:SurrealConnections, table:Table):SurrealSchema =
  return SurrealSchema(rdb:rdb, table:table)

proc new*(_:type SurrealSchema, rdb:SurrealConnections, table:Table, column:Column):SurrealSchema =
  return SurrealSchema(rdb:rdb, table:table, column:column)
