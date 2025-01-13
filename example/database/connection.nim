import std/os
import std/strutils
import ../../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  pgHost = getEnv("PG_HOST")
  pgPort = getEnv("PG_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

# let rdb* = dbOpen(SQLite3, "./db.sqlite3", shouldDisplayLog=true)
let rdb* = dbOpen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=true)
