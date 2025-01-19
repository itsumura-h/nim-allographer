import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../../query_builder/models/mariadb/mariadb_types
import ../../../query_builder/models/mariadb/mariadb_query
import ../../../query_builder/models/mariadb/mariadb_exec
import ../../../query_builder/error
import ../../models/table


proc notAllowedOption*(option, typ, column:string) =
  ## {option} is not allowed in {typ} column {column}
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")

proc notAllowedType*(typ:string) =
  ## Change to {typ} type is not allowed
  raise newException(DbError, &"type {typ} is not allowed")


# ==================================================
# Mariadb
# ==================================================

proc shouldRun*(rdb:MariadbConnections, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_allographer_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc exec*(rdb:MariadbConnections, queries:seq[string]) =
  var isSuccess = false
  let logDisplay = rdb.log.shouldDisplayLog
  let logFile = rdb.log.shouldOutputLogFile
  rdb.log.shouldDisplayLog = false
  rdb.log.shouldOutputLogFile = false

  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except DbError:
    echo getCurrentExceptionMsg()

  rdb.log.shouldDisplayLog = logDisplay
  rdb.log.shouldOutputLogFile = logFile


proc execThenSaveHistory*(rdb:MariadbConnections, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except DbError:
    echo getCurrentExceptionMsg()

  let tableQuery = queries.join("; ")
  let createdAt = (proc():string =
    if rdb is MariadbConnections:
      return now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
    # if rdb.type == SQLite3 or rdb.driver == PostgreSQL:
    #   return $now().utc
    # elif rdb.driver == MariaDB or rdb.driver == MySQL:
    #   return now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
  )()

  rdb.table("_allographer_migrations").insert(%*{
    "name": tableName,
    "query": tableQuery,
    "checksum": checksum,
    "created_at": createdAt,
    "status": isSuccess
  })
  .waitFor


proc execThenSaveHistory*(rdb:MariadbConnections, tableName:string, query:string, checksum:string) =
  var isSuccess = false
  try:
    rdb.raw(query).exec.waitFor
    isSuccess = true
  except DbError:
    echo getCurrentExceptionMsg()

  let createdAt = (proc():string =
    if rdb is MariadbConnections:
      return now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
    # if rdb.driver == SQLite3 or rdb.driver == PostgreSQL:
    #   return $now().utc
    # elif rdb.driver == MariaDB or rdb.driver == MySQL:
    #   return now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
  )()

  rdb.table("_allographer_migrations").insert(%*{
    "name": tableName,
    "query": query,
    "checksum": checksum,
    "created_at": createdAt,
    "status": isSuccess
  })
  .waitFor
