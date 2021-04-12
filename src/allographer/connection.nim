import os, strutils
import dotenv

const
  DRIVER = getEnv("DB_DRIVER","sqlite").string
  DOTENV = getEnv("DOTENV", ".env").string

if (getCurrentDir() / DOTENV).fileExists:
  let env = initDotEnv( getCurrentDir(), DOTENV)
  env.load()

let
  CONN = getEnv("DB_CONNECTION", getCurrentDir() / "db.sqlite3").string
  USER = getEnv("DB_USER", "").string
  PASSWORD = getEnv("DB_PASSWORD", "").string
  DATABASE = getEnv("DB_DATABASE", "").string
  MAX_CONNECTION* = getEnv("DB_MAX_CONNECTION", "1").parseInt

when DRIVER == "sqlite":
  import db_sqlite
  export db_sqlite
  # import sqlite3 except close

when DRIVER == "postgres":
  import ./async/asyncpg
  export asyncpg
  import postgres except close

when DRIVER == "mysql":
  import db_mysql
  export db_mysql
  import mysql except close


proc db*(): DbConn =
  open(CONN, USER, PASSWORD, DATABASE)

proc getDriver*():string =
  return DRIVER

# ==================== async ====================
when DRIVER == "postgres":
  proc pool*():AsyncPool =
    newAsyncPool(CONN, USER, PASSWORD, DATABASE, MAX_CONNECTION)
