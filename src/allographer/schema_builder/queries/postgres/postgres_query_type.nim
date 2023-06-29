import ../../../query_builder/rdb/rdb_types
import ../../models/table
import ../../models/column


type PostgresQuery* = ref object
  rdb*:Rdb
  table*:Table
  column*:Column

proc new*(_:type PostgresQuery, rdb:Rdb, table:Table):PostgresQuery =
  return PostgresQuery(rdb:rdb, table:table)

proc new*(_:type PostgresQuery, rdb:Rdb, table:Table, column:Column):PostgresQuery =
  return PostgresQuery(rdb:rdb, table:table, column:column)
