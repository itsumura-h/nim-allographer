import std/[os, strutils]
import ../src/allographer/query_builder

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  sqliteHost = getEnv("SQLITE_HOST")
  mysqlHost = getEnv("MY_HOST")
  mysqlPort = getEnv("MY_PORT").parseInt
  pgHost = getEnv("PG_HOST")
  pgPort = getEnv("PG_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt


let
  sqliteDb = dbopen(SQLite3, sqliteHost, maxConnections=maxConnections)
  mysqlDb = dbopen(MySQL, database, user, password, mysqlHost, mysqlPort, maxConnections, timeout)
  postgresDb = dbopen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout)
  # db* = sqliteDb
  db* = postgresDb
  # db* = mysqlDb

echo postgresDb.pools[0].postgresConn.status.repr

template asyncBlock*(body:untyped) =
  waitFor (proc(){.async.}=
    body
  )()
