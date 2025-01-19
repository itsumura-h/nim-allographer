import ../../../query_builder/models/postgres/postgres_types
import ../../queries/postgres/postgres_query_type
import ../../models/table
import ../../models/column


proc createSchema*(rdb:PostgresConnections, table:Table):PostgresSchema =
  return PostgresSchema.new(rdb, table)

proc createSchema*(rdb:PostgresConnections, table:Table, column:Column):PostgresSchema =
  return PostgresSchema.new(rdb, table, column)
