import ../../../env
import ../../queries/schema_interface
import ../../../query_builder/models/mysql/mysql_types
import ../../queries/mysql/mysql_query_type
import ../../queries/mysql/mysql_query_impl
import ../../models/table
import ../../models/column


proc createSchema*(rdb:MysqlConnections, table:Table):ISchema =
  when isExistsMysql:
    return MysqlSchema.new(rdb, table).toInterface()

proc createSchema*(rdb:MysqlConnections, table:Table, column:Column):ISchema =
  when isExistsMysql:
    return MysqlSchema.new(rdb, table, column).toInterface()
