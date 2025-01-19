import std/asyncdispatch
import std/os
import std/strutils
import ../../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  surrealHost = getEnv("SURREAL_HOST")
  surrealPort = getEnv("SURREAL_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let surreal* = dbOpen(SurrealDB, "test", "test", "user", "pass", surrealHost, surrealPort, 5, 30, shouldDisplayLog=true).waitFor()
