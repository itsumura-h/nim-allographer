import std/asyncdispatch
import std/json
import std/options
import std/strutils
import std/sha1
import std/times
import ../../../query_builder
import ../../models/table
import ../../models/column
import ./sqlite_query_type
import ./sub/add_column_query


proc shouldRun(rdb:Rdb, table:Table, column:Column, checksum:string, isReset:bool):bool =
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

proc addColumn*(self:SqliteQuery, isReset:bool) =
  addColumnString(self.rdb, self.table, self.column)
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, self.column, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, self.column.queries, checksum)
