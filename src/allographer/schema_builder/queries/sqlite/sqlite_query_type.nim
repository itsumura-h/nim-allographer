import ../../../query_builder/rdb/rdb_types
import ../../models/table
import ../../models/column

type SqliteQuery* = ref object
  rdb*:Rdb
  table*:Table
  column*:Column

proc new*(_:type SqliteQuery, rdb:Rdb, table:Table):SqliteQuery =
  return SqliteQuery(rdb:rdb, table:table)

proc new*(_:type SqliteQuery, rdb:Rdb, table:Table, column:Column):SqliteQuery =
  return SqliteQuery(rdb:rdb, table:table, column:column)
