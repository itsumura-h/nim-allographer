import
  std/json,
  ./base
from async/async_db import open

export
  Driver

proc dbOpen*(driver:Driver, database:string="", user:string="", password:string="",
            host: string="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):Rdb =
  result = new Rdb
  result.driver = driver
  result.conn = open(driver, database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  result.query = newJObject()
  result.isInTransaction = false
