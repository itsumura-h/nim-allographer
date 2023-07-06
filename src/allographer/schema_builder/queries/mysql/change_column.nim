import std/asyncdispatch
import std/strutils
import std/strformat
import std/sha1
import std/options
import std/json
import std/times
import ../../../query_builder
import ../../models/table
import ../../models/column
import ./mysql_query_type
# import ./sub/change_column_query


proc shouldRun(rdb:Rdb, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc execThenSaveHistory(rdb:Rdb, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let tableQuery = queries.join("; ")
  rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": tableQuery,
    "checksum": checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor


proc changeColumn*(self:MysqlQuery, isReset:bool) =
  discard
  # changeColumnString(self.table, self.column)
  # changeIndexString(self.table, self.column)

  # let schema = $self.column.toSchema()
  # let checksum = $schema.secureHash()

  # if shouldRun(self.rdb, self.table, checksum, isReset):
  #   execThenSaveHistory(self.rdb, self.table.name, self.column.queries, checksum)
