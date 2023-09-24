import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../query_builder
import ../models/table


proc notAllowedOption*(option, typ, column:string) =
  ## {option} is not allowed in {typ} column {column}
  raise newException(DbError, &"{option} is not allowed in {typ} column {column}")

proc notAllowedType*(typ:string) =
  ## Change to {typ} type is not allowed
  raise newException(DbError, &"type {typ} is not allowed")


# ==================================================
# Sqlite
# ==================================================

proc shouldRun*(rdb:SqliteConnections, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_allographer_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc exec*(rdb:SqliteConnections, queries:seq[string]) =
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


proc execThenSaveHistory*(rdb:SqliteConnections, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let tableQuery = queries.join("; ")
  let createdAt = (proc():string =
    if rdb is SqliteConnections:
      return $now().utc
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


proc execThenSaveHistory*(rdb:SqliteConnections, tableName:string, query:string, checksum:string) =
  var isSuccess = false
  try:
    rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let createdAt = (proc():string =
    if rdb is SqliteConnections:
      return $now().utc
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


# ==================================================
# Postgres
# ==================================================

proc shouldRun*(rdb:PostgresConnections, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_allographer_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc exec*(rdb:PostgresConnections, queries:seq[string]) =
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


proc execThenSaveHistory*(rdb:PostgresConnections, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let tableQuery = queries.join("; ")
  let createdAt = (proc():string =
    if rdb is PostgresConnections:
      return $now().utc
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


proc execThenSaveHistory*(rdb:PostgresConnections, tableName:string, query:string, checksum:string) =
  var isSuccess = false
  try:
    rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let createdAt = (proc():string =
    if rdb is PostgresConnections:
      return $now().utc
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
  except:
    echo getCurrentExceptionMsg()

  rdb.log.shouldDisplayLog = logDisplay
  rdb.log.shouldOutputLogFile = logFile


proc execThenSaveHistory*(rdb:MariadbConnections, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
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
  except:
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


# ==================================================
# Mysql
# ==================================================

proc shouldRun*(rdb:MysqlConnections, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_allographer_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc exec*(rdb:MysqlConnections, queries:seq[string]) =
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


proc execThenSaveHistory*(rdb:MysqlConnections, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let tableQuery = queries.join("; ")
  let createdAt = (proc():string =
    if rdb is MysqlConnections:
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


proc execThenSaveHistory*(rdb:MysqlConnections, tableName:string, query:string, checksum:string) =
  var isSuccess = false
  try:
    rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let createdAt = (proc():string =
    if rdb is MysqlConnections:
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
  except:
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
  except:
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
  except:
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
