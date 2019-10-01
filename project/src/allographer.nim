import base, grammars, exec
export base, grammars, exec


import os, terminal

## ==================== Command ====================
proc makeConf(driver="sqlite", path="database", args: seq[string]): int =
  var message = ""
  # driver validate check
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    message = "Database driver shoule be sqlite or mysql or postgres"
    styledWriteLine(stdout, fgRed, bgDefault, message, resetStyle)
    return 1

  # create conf file path
  let currentPath = getCurrentDir()
  var confPath = currentPath & "/" & path & ".nim"

  # create file content
  var content = ""
  if driver == "sqlite":
    content = """
import allographer
import db_sqlite

proc conn*(): DbConn =
  open("/home/www/example/db.sqlite3", "", "", "")

export RDB, allographer
    """
  elif driver == "mysql":
    content = """
import allographer
import db_mysql

proc conn*(): DbConn =
  open("localhost:3306", "db_user", "db_password", "db_name")

export RDB, allographer
    """
  elif driver == "postgres":
    content = """
import allographer
import db_postgres

proc conn*(): DbConn =
  open("localhost:5432", "db_user", "db_password", "db_name")

export RDB, allographer
    """

  # generate file
  block:
    let f = open(confPath, fmWrite)
    f.write(content)
    defer:
      f.close()

  message = confPath & " is successfully created!!!"
  styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)

when isMainModule:
  import cligen
  dispatch(makeConf)