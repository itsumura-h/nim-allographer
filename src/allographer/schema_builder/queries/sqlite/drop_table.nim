import std/asyncdispatch
import std/strutils
import std/strformat
import std/sha1
import std/json
import std/times
import std/options
import ../../../query_builder
import ../../enums
import ../../models/table
import ../../models/column
import ./sqlite_query_type
import ./sub/add_column_query


proc shouldRun(rdb:Rdb, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  # let tables = rdb.table("_migrations")
  #           .where("name", "=", table.name)
  #           .orderBy("created_at", Desc)
  #           .get()
  #           .waitFor

  # var histories = newJObject()
  # for table in tables:
  #   histories[table["checksum"].getStr] = table

  # if not histories.hasKey(checksum):
  #   return true

  # return not histories[checksum]["status"].getBool
  let history = rdb.table("_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc execThenSaveHistory(rdb:Rdb, tableName:string, query:string, checksum:string) =
  var isSuccess = false
  try:
    rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": query,
    "checksum": checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor

proc dropTable*(self:SqliteQuery, isReset:bool) =
  let query = &"DROP TABLE IF EXISTS \"{self.table.name}\""
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
