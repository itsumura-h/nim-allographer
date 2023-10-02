import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../../query_builder/models/surreal/surreal_types
import ../../../query_builder/models/surreal/surreal_connections
import ../../../query_builder/models/surreal/surreal_query
import ../../../query_builder/error
import ../../models/table


proc notAllowedOption*(option, typ, column:string) =
  ## {option} is not allowed in {typ} column {column}
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")

proc notAllowedType*(typ:string) =
  ## Change to {typ} type is not allowed
  raise newException(DbError, &"type {typ} is not allowed")


# ==================================================
# SurrealDB
# ==================================================

proc shouldRun*(rdb:SurrealConnections, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_allographer_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc exec*(rdb:SurrealConnections, queries:seq[string]) =
  var isSuccess = false
  let logDisplay = rdb.log.shouldDisplayLog
  let logFile = rdb.log.shouldOutputLogFile
  rdb.log.shouldDisplayLog = false
  rdb.log.shouldOutputLogFile = false
  defer:
    rdb.log.shouldDisplayLog = logDisplay
    rdb.log.shouldOutputLogFile = logFile

  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except DbError:
    echo getCurrentExceptionMsg()


proc execThenSaveHistory*(rdb:SurrealConnections, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false

  try:
    for query in queries:
      let resp = rdb.raw(query).info().waitFor
      for row in resp:
        if row["status"].getStr != "OK":
          raise newException(DbError, row["detail"].getStr)
    isSuccess = true
  except DbError:
    echo getCurrentExceptionMsg()

  let logDisplay = rdb.log.shouldDisplayLog
  let logFile = rdb.log.shouldOutputLogFile
  rdb.log.shouldDisplayLog = false
  rdb.log.shouldOutputLogFile = false
  defer:
    rdb.log.shouldDisplayLog = logDisplay
    rdb.log.shouldOutputLogFile = logFile

  let tableQuery = queries.join("; ")
  let createdAt = now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
  rdb.table("_allographer_migrations").insert(%*{
    "name": tableName,
    "query": tableQuery,
    "checksum": checksum,
    "created_at": createdAt,
    "status": isSuccess
  })
  .waitFor


proc execThenSaveHistory*(rdb:SurrealConnections, tableName:string, query:string, checksum:string) =
  var isSuccess = false
  try:
    let resp = rdb.raw(query).info().waitFor
    if resp.kind == JObject:
      raise newException(DbError, resp["information"].getStr)
    for row in resp:
      if row["status"].getStr != "OK":
        raise newException(DbError, row["detail"].getStr)
    isSuccess = true
  except DbError:
    echo getCurrentExceptionMsg()

  let logDisplay = rdb.log.shouldDisplayLog
  let logFile = rdb.log.shouldOutputLogFile
  rdb.log.shouldDisplayLog = false
  rdb.log.shouldOutputLogFile = false
  defer:
    rdb.log.shouldDisplayLog = logDisplay
    rdb.log.shouldOutputLogFile = logFile

  let createdAt = now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
  rdb.table("_allographer_migrations").insert(%*{
    "name": tableName,
    "query": query,
    "checksum": checksum,
    "created_at": createdAt,
    "status": isSuccess
  })
  .waitFor
