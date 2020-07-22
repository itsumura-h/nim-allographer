import macros, strformat, os
import env

# const
#   DRIVER = getEnv("DB_DRIVER","sqlite").string
#   CONN = getEnv("DB_CONNECTION").string
#   USER = getEnv("DB_USER").string
#   PASSWORD = getEnv("DB_PASSWORD").string
#   DATABASE = getEnv("DB_DATABASE").string

# let envVer* = newEnv()

# macro importDbModule() =
#   var lib =
#     if DRIVER == "sqlite":
#       "sqlite3"
#     else:
#       &"{DRIVER}"

#   parseStmt(fmt"""
# import db_{DRIVER}
# import {lib} except close
# export db_{DRIVER}
# """)
# importDbModule

# proc db*(): DbConn =
#   open(CONN, USER, PASSWORD, DATABASE)

# proc getDriver*():string =
#   return DRIVER

# ======================================================================

let
  envVer* = newEnv()
  CONN = envVer.getStr("DB_CONNECTION")
  USER = envVer.getStr("DB_USER")
  PASSWORD = envVer.getStr("DB_PASSWORD")
  DATABASE = envVer.getStr("DB_DATABASE")

when defined mysql:
  import db_mysql
  import mysql
  export db_mysql
  let DRIVER = "mysql"

  proc db*(): DbConn =
    open(CONN, USER, PASSWORD, DATABASE)

when defined postgres:
  import db_postgres
  import postgres
  export db_postgres
  let DRIVER = "postgres"

  proc db*(): DbConn =
    open(CONN, USER, PASSWORD, DATABASE)

else:
  import db_sqlite
  import sqlite3
  export db_sqlite
  let DRIVER = "sqlite"

  proc db*(): DbConn =
    open(CONN, USER, PASSWORD, DATABASE)

proc getDriver*():string =
  return DRIVER
