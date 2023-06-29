import ../../../query_builder/rdb/rdb_types
import ../../models/table
import ../../models/column

type PostgresService* = ref object
  rdb*:Rdb
  table*:Table

proc new*(_:type PostgresService, rdb:Rdb, table:Table):PostgresService =
  return PostgresService(rdb:rdb, table:table)
