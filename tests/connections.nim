import std/asyncdispatch
import std/macros
import std/os
import std/strutils
import ../src/allographer/connection
import ../src/allographer/query_builder


let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  sqliteHost = getEnv("SQLITE_HOST")
  mariadbHost = getEnv("MARIA_HOST")
  mysqlPort = getEnv("MY_PORT").parseInt
  pgHost = getEnv("PG_HOST")
  pgPort = getEnv("PG_PORT").parseInt
  surrealHost = getEnv("SURREAL_HOST")
  surrealPort = getEnv("SURREAL_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let sqlite* = dbOpen(SQLite3, ":memory:", maxConnections=maxConnections, shouldDisplayLog=true)
# let sqlite* = dbopen(SQLite3, getCurrentDir() / "db.sqlite3" , maxConnections=maxConnections, shouldDisplayLog=true)
let postgres* = dbOpen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=true)
let mariadb* = dbopen(MariaDB, database, user, password, mariadbHost, mysqlPort, maxConnections, timeout, shouldDisplayLog=true)
# let surreal* = dbOpen(SurrealDb, "test", "test", "user", "pass", surrealHost, surrealPort, 5, 30, false, false).waitFor()

let dbConnections* :seq[PostgresConnections] = @[
  # dbopen(SQLite3, getCurrentDir() / "db.sqlite3", maxConnections=maxConnections, timeout=timeout, shouldDisplayLog=true),
  # dbopen(SQLite3, ":memory:", maxConnections=maxConnections, timeout=timeout, shouldDisplayLog=true),
  dbOpen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=true)
]

# let dbConnectionsTransacion* = @[
#   dbopen(SQLite3, sqliteHost, maxConnections=95, timeout=timeout, shouldDisplayLog=false),
#   dbopen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=false),
#   dbopen(MariaDB, database, user, password, mariadbHost, mysqlPort, maxConnections, timeout, shouldDisplayLog=false),
# ]

template asyncBlock*(rdb, body:untyped) =
  (proc(){.async.}=
    body
  )()
  .waitFor()

macro runAllDb*(heads, key, body:untyped):untyped =
  ## .. code-block:: Nim
  ##   runAllDb([sqlite, postgres, mysql, mariadb], rdb):
  ##     echo rdb.table("user").get().await
  var res = ""
  for row in heads:
    var body = body.repr
    let key = key.repr
    let row = row.repr
    body = body.replace(key, row)
    res.add(body & "\n")
  echo res
  return res.parseStmt
