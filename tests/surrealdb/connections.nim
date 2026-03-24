import std/asyncdispatch
import std/os
import std/strutils
import ../../src/allographer/connection

proc envIntDefault(key: string, defaultValue: int): int =
  let value = getEnv(key)
  if value.len == 0:
    return defaultValue
  return value.parseInt

let
  maxConnections = envIntDefault("DB_MAX_CONNECTION", 5)
  timeout = envIntDefault("DB_TIMEOUT", 30)

let surreal* = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000, maxConnections, timeout, shouldDisplayLog=true).waitFor()
