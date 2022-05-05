import std/[os, strutils]
import ../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  sqliteHost = getEnv("SQLITE_HOST")
  mysqlHost = getEnv("MY_HOST")
  mariadbHost = getEnv("MARIA_HOST")
  mysqlPort = getEnv("MY_PORT").parseInt
  pgHost = getEnv("PG_HOST")
  pgPort = getEnv("PG_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let
  rdb* = dbopen(SQLite3, ":memory:", maxConnections=maxConnections, shouldDisplayLog=true)
  # rdb* = dbopen(SQLite3, ":memory:", maxConnections=maxConnections)
  # rdb* = dbopen(MySQL, database, user, password, mysqlHost, mysqlPort, maxConnections, timeout)
  # rdb* = dbopen(MariaDB, database, user, password, mariadbHost, mysqlPort, maxConnections, timeout)
  # rdb* = dbopen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout)

template asyncBlock*(body:untyped) =
  waitFor (proc(){.async.}=
    body
  )()
