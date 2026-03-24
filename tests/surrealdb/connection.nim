import std/asyncdispatch
import std/os
import std/strutils
import ../../src/allographer/connection

proc envStringDefault(key, defaultValue: string): string =
  let value = getEnv(key)
  if value.len == 0:
    return defaultValue
  return value

proc envIntDefault(key: string, defaultValue: int): int =
  let value = getEnv(key)
  if value.len == 0:
    return defaultValue
  return value.parseInt

let
  database = envStringDefault("DB_DATABASE", "test")
  user = envStringDefault("DB_USER", "user")
  password = envStringDefault("DB_PASSWORD", "pass")
  surrealHost = envStringDefault("SURREAL_HOST", "http://surreal")
  surrealPort = envIntDefault("SURREAL_PORT", 8000)
  maxConnections = envIntDefault("DB_MAX_CONNECTION", 5)
  timeout = envIntDefault("DB_TIMEOUT", 30)

let surreal* = dbOpen(SurrealDB, database, database, user, password, surrealHost, surrealPort, maxConnections, timeout, shouldDisplayLog=true).waitFor()
