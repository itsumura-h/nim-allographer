import os, terminal, strformat

proc makeConf*(args: seq[string]): int =
  ## Generate .env to define DB connection and logging

  var message = ""
  # define path
  var confPath = getCurrentDir() & "/.env"
  var content = &"""
# DB Connection
DB_CONNECTION="{getCurrentDir()}/db.sqlite3"
DB_USER=""
DB_PASSWORD=""
DB_DATABASE=""

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
