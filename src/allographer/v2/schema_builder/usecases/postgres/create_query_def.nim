import ../../../query_builder/models/postgres/postgres_types
import ../../queries/schema_interface
import ../../queries/postgres/postgres_query_type
import ../../queries/postgres/postgres_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:PostgresConnections, table:Table):ISchema =
  return PostgresSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:PostgresConnections, table:Table, column:Column):ISchema =
  return PostgresSchema.new(rdb, table, column).toInterface()
