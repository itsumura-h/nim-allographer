import macros, strformat, os

const
  DRIVER = getEnv("db.driver","sqlite").string
  CONN = getEnv("db.connection").string
  USER = getEnv("db.user").string
  PASSWORD = getEnv("db.password").string
  DATABASE = getEnv("db.database").string

macro importDbModule() =
  parseStmt(fmt"""
import db_{DRIVER}
""")
importDbModule

proc db*(): DbConn =
  open(CONN, USER, PASSWORD, DATABASE)

proc getDriver*():string =
  return DRIVER
