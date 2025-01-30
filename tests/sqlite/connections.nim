import std/os
import std/strutils
import ../../src/allographer/connection

let
  sqliteHost = getEnv("SQLITE_HOST")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let sqlite* = dbOpen(SQLite3, sqliteHost, maxConnections, timeout, shouldDisplayLog=true)
