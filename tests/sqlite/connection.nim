import std/os
import std/strutils
import ../../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  sqliteHost = getEnv("SQLITE_HOST")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let sqlite* = dbOpen(SQLite3, ":memory:", maxConnections=maxConnections, shouldDisplayLog=true)
# let sqlite* = dbopen(SQLite3, getCurrentDir() / "db.sqlite3" , maxConnections=maxConnections, shouldDisplayLog=true)
