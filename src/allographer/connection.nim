import macros, strformat

macro importDatabaseConf() =
  let projectPath = getProjectpath()
  parseStmt(fmt"""
import {projectPath}/conf/database
""")
importDatabaseConf

macro importDbModule() =
  parseStmt(fmt"""
import db_{DRIVER}
""")
importDbModule

proc db*(): DbConn =
  open(CONN, USER, PASSWORD, DATABASE)

proc getDriver*():string =
  return DRIVER
