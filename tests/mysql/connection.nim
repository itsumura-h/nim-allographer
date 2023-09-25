import std/os
import std/strutils
import ../../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  mysqlHost = getEnv("MY_HOST")
  mysqlPort = getEnv("MY_PORT").parseInt.int32
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let mysql* = dbOpen(MySQL, database, user, password, mysqlHost, mysqlPort, maxConnections, timeout, shouldDisplayLog=true)
