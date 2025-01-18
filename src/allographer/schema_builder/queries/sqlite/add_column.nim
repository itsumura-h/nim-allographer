import std/json
import checksums/sha1
import ../../models/table
import ../../models/column
import ./sqlite_query_type
import ./sub/add_column_query
import ./schema_utils


# proc shouldRun(rdb:SqliteConnections, table:Table, column:Column, checksum:string, isReset:bool):bool =
#   if isReset:
#     return true

#   let history = rdb.table("_allographer_migrations")
#                   .where("checksum", "=", checksum)
#                   .first()
#                   .waitFor
#   return not history.isSome() or not history.get()["status"].getBool


# proc execThenSaveHistory(rdb:SqliteConnections, tableName:string, queries:seq[string], checksum:string) =
#   var isSuccess = false
#   try:
#     for query in queries:
#       rdb.raw(query).exec.waitFor
#     isSuccess = true
#   except DbError:
#     echo getCurrentExceptionMsg()

#   let tableQuery = queries.join("; ")
#   rdb.table("_allographer_migrations").insert(%*{
#     "name": tableName,
#     "query": tableQuery,
#     "checksum": checksum,
#     "created_at": $now().utc,
#     "status": isSuccess
#   })
#   .waitFor

proc addColumn*(self:SqliteSchema, isReset:bool) =
  let queries = addColumnString(self.rdb, self.table, self.column)
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
