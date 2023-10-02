import ../../../query_builder/models/mariadb/mariadb_types
import ../../queries/mariadb/mariadb_query_type
import ../../queries/mariadb/mariadb_query_impl
import ../../queries/schema_interface
import ../../models/table
import ../../models/column


proc createSchema*(rdb:MariadbConnections, table:Table):ISchema =
  return MariadbSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:MariadbConnections, table:Table, column:Column):ISchema =
  return MariadbSchema.new(rdb, table, column).toInterface()
