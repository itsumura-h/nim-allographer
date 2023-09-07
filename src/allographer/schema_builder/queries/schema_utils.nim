import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
# from std/db_common import DbError
# import ../../query_builder/rdb/rdb_types
import ../../query_builder
# import ../../query_builder/error
# import ../../query_builder/models/sqlite/sqlite_types
# import ../../query_builder/models/sqlite/sqlite_query
# import ../../query_builder/rdb/rdb_interface
# import ../../query_builder/rdb/query/grammar
# import ../../query_builder/surreal/surreal_types
# import ../../query_builder/surreal/surreal_interface
# import ../../query_builder/surreal/query/grammar as surreal_grammar
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

  let history = rdb.table("_migrations")
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

  rdb.table("_migrations").insert(%*{
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

  rdb.table("_migrations").insert(%*{
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

  let history = rdb.table("_migrations")
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

  rdb.table("_migrations").insert(%*{
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

  rdb.table("_migrations").insert(%*{
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

  let history = rdb.table("_migrations")
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

  rdb.table("_migrations").insert(%*{
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

  rdb.table("_migrations").insert(%*{
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


# ==================================================
# SurrealDB
# ==================================================


# proc shouldRun*(rdb:SurrealDb, table:Table, checksum:string, isReset:bool):bool =
#   if isReset:
#     return true

#   let history = rdb.table("_migrations")
#                   .where("checksum", "=", checksum)
#                   .first()
#                   .waitFor
#   return not history.isSome() or not history.get()["status"].getBool


# proc exec*(rdb:SurrealDb, queries:seq[string]) =
#   var isSuccess = false
#   let logDisplay = rdb.log.shouldDisplayLog
#   let logFile = rdb.log.shouldOutputLogFile
#   rdb.log.shouldDisplayLog = false
#   rdb.log.shouldOutputLogFile = false

#   try:
#     for query in queries:
#       rdb.raw(query).exec.waitFor
#     isSuccess = true
#   except:
#     echo getCurrentExceptionMsg()

#   rdb.log.shouldDisplayLog = logDisplay
#   rdb.log.shouldOutputLogFile = logFile


# proc execThenSaveHistory*(rdb:SurrealDb, tableName:string, queries:seq[string], checksum:string) =
#   var isSuccess = false

#   try:
#     for query in queries:
#       let resp = rdb.raw(query).info().waitFor
#       for row in resp:
#         if row["status"].getStr != "OK":
#           raise newException(DbError, row["detail"].getStr)
#     isSuccess = true
#   except:
#     echo getCurrentExceptionMsg()

#   let logDisplay = rdb.log.shouldDisplayLog
#   let logFile = rdb.log.shouldOutputLogFile
#   rdb.log.shouldDisplayLog = false
#   rdb.log.shouldOutputLogFile = false

#   let tableQuery = queries.join("; ")
#   let createdAt = now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
#   rdb.table("_migrations").insert(%*{
#     "name": tableName,
#     "query": tableQuery,
#     "checksum": checksum,
#     "created_at": createdAt,
#     "status": isSuccess
#   })
#   .waitFor

#   rdb.log.shouldDisplayLog = logDisplay
#   rdb.log.shouldOutputLogFile = logFile


# proc execThenSaveHistory*(rdb:SurrealDb, tableName:string, query:string, checksum:string) =
#   var isSuccess = false
#   try:
#     let resp = rdb.raw(query).info().waitFor
#     for row in resp:
#       if row["status"].getStr != "OK":
#         raise newException(DbError, row["detail"].getStr)
#     isSuccess = true
#   except:
#     echo getCurrentExceptionMsg()

#   let logDisplay = rdb.log.shouldDisplayLog
#   let logFile = rdb.log.shouldOutputLogFile
#   rdb.log.shouldDisplayLog = false
#   rdb.log.shouldOutputLogFile = false

#   let createdAt = now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff")
#   rdb.table("_migrations").insert(%*{
#     "name": tableName,
#     "query": query,
#     "checksum": checksum,
#     "created_at": createdAt,
#     "status": isSuccess
#   })
#   .waitFor

#   rdb.log.shouldDisplayLog = logDisplay
#   rdb.log.shouldOutputLogFile = logFile
