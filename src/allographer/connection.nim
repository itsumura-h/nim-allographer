import macros, strformat, os

# macro importDatabaseConf() =
#   let projectPath = getProjectpath()
#   parseStmt(fmt"""
# import {projectPath}/conf/database
# """)
# importDatabaseConf
const
  DRIVER = getEnv("db.driver","sqlite")
  CONN = getEnv("db.connection")
  USER = getEnv("db.user")
  PASSWORD = getEnv("db.password")
  DATABASE = getEnv("db.database")

macro importDbModule() =
  parseStmt(fmt"""
import db_{DRIVER}
""")
importDbModule

proc db*(): DbConn =
  open(CONN, USER, PASSWORD, DATABASE)

proc getDriver*():string =
  return DRIVER
