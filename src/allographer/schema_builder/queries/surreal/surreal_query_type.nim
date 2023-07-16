import ../../../query_builder/surreal/surreal_types
import ../../models/table
import ../../models/column


type SurrealQuery* = ref object
  rdb*:SurrealDb
  table*:Table
  column*:Column

proc new*(_:type SurrealQuery, rdb:SurrealDb, table:Table):SurrealQuery =
  return SurrealQuery(rdb:rdb, table:table)

proc new*(_:type SurrealQuery, rdb:SurrealDb, table:Table, column:Column):SurrealQuery =
  return SurrealQuery(rdb:rdb, table:table, column:column)
