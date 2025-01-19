import ../../../query_builder/models/mysql/mysql_types
import ../../queries/mysql/mysql_query_type
import ../../models/table
import ../../models/column


proc createSchema*(rdb:MysqlConnections, table:Table):MysqlSchema =
  return MysqlSchema.new(rdb, table)

proc createSchema*(rdb:MysqlConnections, table:Table, column:Column):MysqlSchema =
  return MysqlSchema.new(rdb, table, column)
