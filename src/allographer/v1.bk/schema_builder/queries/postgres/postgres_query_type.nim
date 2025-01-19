import ../../../query_builder/models/postgres/postgres_types
import ../../models/table
import ../../models/column


type PostgresSchema* = ref object
  rdb*:PostgresConnections
  table*:Table
  column*:Column

proc new*(_:type PostgresSchema, rdb:PostgresConnections, table:Table):PostgresSchema =
  return PostgresSchema(rdb:rdb, table:table)

proc new*(_:type PostgresSchema, rdb:PostgresConnections, table:Table, column:Column):PostgresSchema =
  return PostgresSchema(rdb:rdb, table:table, column:column)
