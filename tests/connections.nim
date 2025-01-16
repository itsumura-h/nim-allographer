import std/asyncdispatch
import std/os
import std/strutils
import ../src/allographer/connection

let
  pgUrl = getEnv("PG_URL")
  mariadbUrl = getEnv("MARIA_URL")
  mysqlUrl = getEnv("MY_URL")
  sqliteHost = getEnv("SQLITE_HOST")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let postgres* = dbOpen(PostgreSQL, pgUrl, maxConnections, timeout, shouldDisplayLog=true)
let mariadb* = dbOpen(MariaDB, mariadbUrl, maxConnections, timeout, shouldDisplayLog=true)
let mysql* = dbOpen(MySQL, mysqlUrl, maxConnections, timeout, shouldDisplayLog=true)
let sqlite* = dbOpen(SQLite3, sqliteHost, maxConnections, timeout, shouldDisplayLog=true)
let surreal* = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000, maxConnections, timeout, shouldDisplayLog=true).waitFor()
