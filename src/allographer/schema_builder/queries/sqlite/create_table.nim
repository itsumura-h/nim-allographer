import std/asyncdispatch
import std/strformat
import std/strutils
import std/times
import std/sha1
import std/options
import std/json
import ../../../query_builder/enums as query_builder_enums
import ../../../query_builder/rdb/rdb_types
import ../../../query_builder/rdb/rdb_interface
import ../../../query_builder/rdb/query/grammar
import ../../../query_builder/error
import ../../enums
import ../../models/table
import ../../models/column
import ./sqlite_query_type
import ./sub/create_column_query


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

proc createTable*(self: SqliteQuery, isReset:bool) =
  for i, column in self.table.columns:
    createColumnString(column)
    createForeignString(column)
    createIndexString(self.table, column)

  var queries:seq[string] = @[]
  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]
  for i, column in self.table.columns:
    if query.len > 0: query.add(", ")
    query.add(column.query)

    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(column.foreignQuery)
    
    if column.indexQuery.len > 0:
      indexQuery.add(column.indexQuery)

  if foreignQuery.len > 0:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS \"{self.table.name}\" ({query}, {foreignQuery})"
    )
  else:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS \"{self.table.name}\" ({query})"
    )

  if indexQuery.len > 0:
    queries.add(indexQuery)

  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
