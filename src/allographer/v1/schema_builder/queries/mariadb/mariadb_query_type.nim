import ../../../query_builder/models/mariadb/mariadb_types
import ../../models/table
import ../../models/column


type MariadbSchema* = ref object
  rdb*:MariadbConnections
  table*:Table
  column*:Column

proc new*(_:type MariadbSchema, rdb:MariadbConnections, table:Table):MariadbSchema =
  return MariadbSchema(rdb:rdb, table:table)

proc new*(_:type MariadbSchema, rdb:MariadbConnections, table:Table, column:Column):MariadbSchema =
  return MariadbSchema(rdb:rdb, table:table, column:column)
