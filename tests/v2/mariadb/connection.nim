import std/os
import std/strutils
import ../../../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  mariadbHost = getEnv("MARIA_HOST")
  mysqlPort = getEnv("MY_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let mariadb* = dbOpen(MariaDB, database, user, password, mariadbHost, mysqlPort, maxConnections, timeout, shouldDisplayLog=true)
