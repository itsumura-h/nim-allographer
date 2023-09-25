import ../../../query_builder/models/mysql/mysql_types
import ../../models/table
import ../../models/column


type MysqlSchema* = ref object
  rdb*:MysqlConnections
  table*:Table
  column*:Column

proc new*(_:type MysqlSchema, rdb:MysqlConnections, table:Table):MysqlSchema =
  return MysqlSchema(rdb:rdb, table:table)

proc new*(_:type MysqlSchema, rdb:MysqlConnections, table:Table, column:Column):MysqlSchema =
  return MysqlSchema(rdb:rdb, table:table, column:column)
