import os, terminal, strformat, parsecfg
import ../../util

proc makeConf*(args: seq[string]): int =
  ## Generate config/database.ini for setup DB connection infomations

  var message = ""
  # define path
  var confPath = getCurrentDir() & "/config/database.ini"
  var content = &"""
[RDB]
driver: "sqlite"
conn: "{getCurrentDir()}/db.sqlite3"
user: ""
password: ""
database: ""
"""

  try:
    block:
      createDir(parentDir(confPath))
      let f = open(confPath, fmWrite)
      f.write(content)
      defer: f.close()

    message = confPath & " is successfully created!!!"
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
  except:
    getCurrentExceptionMsg().echoErrorMsg()

  # Generate Logging conf file
  confPath = getCurrentDir() & "/config/logging.ini"
  content = &"""
[Log]
display: "true"
file: "true"
logDir: "{getCurrentDir()}/logs"
"""

  try:
    block:
      createDir(parentDir(confPath))
      let f = open(confPath, fmWrite)
      f.write(content)
      defer: f.close()

    message = confPath & " is successfully created!!!"
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
  except:
    getCurrentExceptionMsg().echoErrorMsg()


proc loadConf*(args: seq[string]): int =
  ## Apply DB connection informations to framework

  var message = ""
  # define path
  let confPath = getCurrentDir() & "/config/database.ini"

  # load conf
  var conf = loadConfig(confPath)
  let driver = conf.getSectionValue("RDB", "driver")
  let conn = conf.getSectionValue("RDB", "conn")
  let user = conf.getSectionValue("RDB", "user")
  let password = conf.getSectionValue("RDB", "password")
  let database = conf.getSectionValue("RDB", "database")

  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    message = "RDB.driver shoule be sqlite or mysql or postgres"
    styledWriteLine(stdout, fgRed, bgDefault, message, resetStyle)
    return 1

  var targetPath = normalizedPath(getAppDir() & "/../connection.nim")
  let content = &"""
import db_{driver}

proc db*(): DbConn =
  open("{conn}", "{user}", "{password}", "{database}")

const DRIVER = "{driver}"

proc getDriver*():string =
  return DRIVER
"""

  try:
    block:
      let f = open(targetPath, fmWrite)
      f.write(content)
      defer: f.close()

    message = confPath & " is successfully loaded!!!"
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)

    message = targetPath & " is successfully edited!!!"
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
  except:
    getCurrentExceptionMsg().echoErrorMsg()
