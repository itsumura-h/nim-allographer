import std/os
import std/strutils
import ../../src/allographer/connection

let
  mysqlUrl = getEnv("MY_URL")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let mysql* = dbOpen(MySQL, mysqlUrl, maxConnections, timeout, shouldDisplayLog=true)
