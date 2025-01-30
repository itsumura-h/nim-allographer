import std/asyncdispatch
import std/os
import std/strutils
import ../../src/allographer/connection

let
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let surreal* = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000, maxConnections, timeout, shouldDisplayLog=true).waitFor()
