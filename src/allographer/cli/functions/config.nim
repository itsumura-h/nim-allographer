import os, terminal, strformat

proc makeConf*(args: seq[string]): int =
  ## Generate config.nims to define DB connection and logging

  var message = ""
  # define path
  var confPath = getCurrentDir() & "/config.nims"
  var content = &"""
import os

# DB Connection
putEnv("DB_DRIVER", "sqlite") # sqlite / mysql / postgres
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

  confPath = getCurrentDir() & "/.env"
  content = &"""
DB_CONNECTION="{getCurrentDir()}/db.sqlite3"
DB_USER=""
DB_PASSWORD=""
DB_DATABASE=""
DB_MAX_CONNECTION=95

# Logging
LOG_IS_DISPLAY=true
LOG_IS_FILE=true
LOG_DIR="{getCurrentDir()}/logs"
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