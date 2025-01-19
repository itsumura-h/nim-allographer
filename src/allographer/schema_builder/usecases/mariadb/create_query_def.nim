import ../../../query_builder/models/mariadb/mariadb_types
import ../../queries/mariadb/mariadb_query_type
import ../../models/table
import ../../models/column


proc createSchema*(rdb:MariadbConnections, table:Table):MariadbSchema =
  return MariadbSchema.new(rdb, table)

proc createSchema*(rdb:MariadbConnections, table:Table, column:Column):MariadbSchema =
  return MariadbSchema.new(rdb, table, column)
