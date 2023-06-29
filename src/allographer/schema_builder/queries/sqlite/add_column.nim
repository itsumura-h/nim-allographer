import std/asyncdispatch
import std/json
import std/options
import std/strutils
import std/sha1
import std/times
import std/json
import ../../../query_builder
import ../../enums
import ../../models/table
import ../../models/column
import ./sqlite_query_type
import ./sub/add_column_query


proc shouldRun(rdb:Rdb, table:Table, column:Column, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  # if column.typ == rdbIncrements:
  #   let columns = rdb.table(table.name).columns().waitFor
  #   return not columns.contains(column.name)
  # else:
  #   let tables = rdb.table("_migrations")
  #                   .where("name", "=", table.name)
  #                   .orderBy("created_at", Desc)
  #                   .get()
  #                   .waitFor

  #   var histories = newJObject()
  #   for table in tables:
  #     histories[table["checksum"].getStr] = table

  #   if not histories.hasKey(checksum):
  #     return true

  #   return not histories[checksum]["status"].getBool
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
