import os, terminal, strformat

proc makeConf*(args: seq[string]): int =
  ## Generate config.nims to define DB connection and logging

  var message = ""
  # define path
  var confPath = getCurrentDir() & "/config.nims"
  var content = &"""
import os

# DB Connection
putEnv("db.driver", "sqlite")
putEnv("db.connection", "{getCurrentDir()}/db.sqlite3")
putEnv("db.user", "")
putEnv("db.password", "")
putEnv("db.database", "")

# Logging
putEnv("log.isDisplay", "true")
putEnv("log.isFile", "true")
putEnv("log.dir", "{getCurrentDir()}/logs")
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
    message = getCurrentExceptionMsg()
    styledWriteLine(stdout, fgRed, bgDefault, message, resetStyle)
