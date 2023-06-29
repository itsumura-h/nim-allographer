import std/asyncdispatch
import std/strformat
import std/strutils
import std/times
import std/sha1
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


proc exec(rdb:Rdb, queries:seq[string]) =
  var isSuccess = false
  let logDisplay = rdb.log.shouldDisplayLog
  let logFile = rdb.log.shouldOutputLogFile

  rdb.log.shouldDisplayLog = false
  rdb.log.shouldOutputLogFile = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  rdb.log.shouldDisplayLog = logDisplay
  rdb.log.shouldOutputLogFile = logFile


proc createMigrationTable*(self: SqliteQuery) =
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
    
    if column.isUnique or column.isIndex:
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

  exec(self.rdb, queries)
