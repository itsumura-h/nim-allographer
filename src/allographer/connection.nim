import macros, strformat, os

const
  DRIVER = getEnv("DB_DRIVER","sqlite").string
  CONN = getEnv("DB_CONNECTION").string
  USER = getEnv("DB_USER").string
  PASSWORD = getEnv("DB_PASSWORD").string
  DATABASE = getEnv("DB_DATABASE").string

macro importDbModule() =
  var lib =
    if DRIVER == "sqlite":
      "sqlite3"
    else:
      &"{DRIVER}"

  parseStmt(fmt"""
import db_{DRIVER}
import {lib} except close
export db_{DRIVER}
""")
importDbModule

proc db*(): DbConn =
  open(CONN, USER, PASSWORD, DATABASE)

proc getDriver*():string =
  return DRIVER
