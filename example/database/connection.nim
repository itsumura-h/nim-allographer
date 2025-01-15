import std/asyncdispatch
import std/os
import std/strutils
import ../../src/allographer/connection

let
  pgUrl = getEnv("PG_URL")
  mariaUrl = getEnv("MARIA_URL")
  mysqlUrl = getEnv("MYSQL_URL")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

# let rdb* = dbOpen(SQLite3, "./db.sqlite3", shouldDisplayLog=true)
let rdb* = dbOpen(PostgreSQL, pgUrl, maxConnections, timeout, shouldDisplayLog=true)
# let rdb* = dbOpen(Mariadb, mariaUrl, maxConnections, timeout, shouldDisplayLog=true)
# let rdb* = dbOpen(MySQL, mysqlUrl, maxConnections, timeout, shouldDisplayLog=true)
# let rdb* = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000, 5, 30, shouldDisplayLog=true).waitFor()
