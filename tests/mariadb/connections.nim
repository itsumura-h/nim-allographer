import std/os
import std/strutils
import ../../src/allographer/connection

let
  mariadbUrl = getEnv("MARIA_URL")
  mysqlUrl = getEnv("MY_URL")
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let mariadb* = dbOpen(MariaDB, mariadbUrl, maxConnections, timeout, shouldDisplayLog=true)
