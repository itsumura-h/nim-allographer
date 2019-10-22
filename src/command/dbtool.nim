import os, terminal, parsecfg, strformat


proc makeConf(args: seq[string]): int =
  ## Generate config/database.ini for setup DB connection infomations

  var message = ""
  # define path
  let confPath = getCurrentDir() & "/config/database.ini"
  let content = &"""
[Connection]
driver: "sqlite"
conn: "{getCurrentDir()}/db.sqlite3"
user: ""
password: ""
database: ""

[Log]
display: "true"
file: "true"
"""

  block:
    createDir(parentDir(confPath))
    let f = open(confPath, fmWrite)
    f.write(content)
    defer:
      f.close()

  message = confPath & " is successfully created!!!"
  styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)


proc loadConf(args: seq[string]): int =
  ## Apply DB connection informations to framework

  var message = ""
  # define path
  let confPath = getCurrentDir() & "/config/database.ini"

  # load conf
  var conf = loadConfig(confPath)
  let driver = conf.getSectionValue("Connection", "driver")
  let conn = conf.getSectionValue("Connection", "conn")
  let user = conf.getSectionValue("Connection", "user")
  let password = conf.getSectionValue("Connection", "password")
  let database = conf.getSectionValue("Connection", "database")

  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    message = "Connection.driver shoule be sqlite or mysql or postgres"
    styledWriteLine(stdout, fgRed, bgDefault, message, resetStyle)
    return 1

  var targetPath = normalizedPath(getAppDir() & "/../database.nim")
  let content = &"""
import db_{driver}

proc db*(): DbConn =
  open("{conn}", "{user}", "{password}", "{database}")
"""
  block:
    let f = open(targetPath, fmWrite)
    f.write(content)
    defer:
      f.close()

  try:
    message = confPath & " is successfully loaded!!!"
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)

    message = targetPath & " is successfully edited!!!"
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
  except:
    echo getCurrentExceptionMsg()


when isMainModule:
  import cligen
  dispatchMulti([makeConf], [loadConf])
