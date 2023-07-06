import ../../../query_builder/rdb/rdb_types
import ../../models/table
import ../../models/column


type MysqlQuery* = ref object
  rdb*:Rdb
  table*:Table
  column*:Column

proc new*(_:type MysqlQuery, rdb:Rdb, table:Table):MysqlQuery =
  return MysqlQuery(rdb:rdb, table:table)

proc new*(_:type MysqlQuery, rdb:Rdb, table:Table, column:Column):MysqlQuery =
  return MysqlQuery(rdb:rdb, table:table, column:column)
