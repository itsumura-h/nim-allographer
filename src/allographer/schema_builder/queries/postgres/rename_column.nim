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
import ./postgres_query_type
import ./sub/add_column_query


proc shouldRun(rdb:Rdb, table:Table, column:Column, checksum:string, isReset:bool):bool =
  if isReset:
    return true

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


proc renameColumn*(self:PostgresQuery, isReset:bool) =
  let query = &"ALTER TABLE \"{self.table.name}\" RENAME COLUMN \"{self.column.previousName}\" TO \"{self.column.name}\""
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, self.column, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
