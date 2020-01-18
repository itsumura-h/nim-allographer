import os, terminal, strformat

proc makeConf*(args: seq[string]): int =
  ## Generate config.nims to define DB connection and logging

  var message = ""
  # define path
  var confPath = getCurrentDir() & "/config.nims"
  var content = &"""
import os

# DB Connection
putEnv("DB_DRIVER", "sqlite")
putEnv("DB_CONNECTION", "{getCurrentDir()}/db.sqlite3")
putEnv("DB_USER", "")
putEnv("DB_PASSWORD", "")
putEnv("DB_DATABASE", "")

# Logging
putEnv("LOG_IS_DISPLAY", "true")
putEnv("LOG_IS_FILE", "true")
putEnv("LOG_DIR", "{getCurrentDir()}/logs")
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
