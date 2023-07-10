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
import ../../enums
import ./mysql_query_type
import ./sub/change_column_query


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

  let query = queries.join("; ")
  rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": query,
    "checksum": checksum,
    "created_at": $now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff"),
    "status": isSuccess
  })
  .waitFor


proc changeColumn*(self:MysqlQuery, isReset:bool) =
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  var queries:seq[string]
  queries.add(&"ALTER TABLE `{self.table.name}` DROP INDEX IF EXISTS `{self.column.name}`") # unique
  queries.add(&"ALTER TABLE `{self.table.name}` DROP INDEX IF EXISTS `{self.table.name}_{self.column.name}_index`")
  changeColumnString(self.table, self.column)
  queries.add(self.column.queries)

  if self.column.isIndex:
    let indexQuery = addIndexString(self.column, self.table)
    queries.add(indexQuery)

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
