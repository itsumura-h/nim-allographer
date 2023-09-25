import ../../../query_builder/models/mysql/mysql_types
import ../../queries/mysql/mysql_query_type
import ../../queries/mysql/mysql_query_impl
import ../../queries/schema_interface
import ../../models/table
import ../../models/column


proc createSchema*(rdb:MysqlConnections, table:Table):ISchema =
  return MysqlSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:MysqlConnections, table:Table, column:Column):ISchema =
  return MysqlSchema.new(rdb, table, column).toInterface()
