import std/os
import std/strutils
import ../../src/allographer/connection

let
  pgUrl = getEnv("PG_URL")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let postgres* = dbOpen(PostgreSQL, pgUrl, maxConnections, timeout, shouldDisplayLog=true)
