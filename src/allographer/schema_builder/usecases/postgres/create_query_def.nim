import ../../../env
import ../../queries/schema_interface
import ../../../query_builder/models/postgres/postgres_types
import ../../queries/postgres/postgres_query_type
import ../../queries/postgres/postgres_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:PostgresConnections, table:Table):ISchema =
  when isExistsPostgres:
    return PostgresSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:PostgresConnections, table:Table, column:Column):ISchema =
  when isExistsPostgres:
    return PostgresSchema.new(rdb, table, column).toInterface()
