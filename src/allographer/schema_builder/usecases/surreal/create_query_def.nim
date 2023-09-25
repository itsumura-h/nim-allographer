import ../../queries/schema_interface
import ../../../query_builder/models/surreal/surreal_types
import ../../queries/surreal/surreal_query_type
import ../../queries/surreal/surreal_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:SurrealConnections, table:Table):ISchema =
  return SurrealSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:SurrealConnections, table:Table, column:Column):ISchema =
  return SurrealSchema.new(rdb, table, column).toInterface()
