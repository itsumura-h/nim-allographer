import json
from async/async_db import open
from async/database/base as asyncBase import Driver
import base

export
  Driver

proc dbOpen*(driver:Driver, database:string="", user:string="", password:string="",
            host: string="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):Rdb =
  result = new Rdb
  result.conn = open(driver, database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  result.query = newJObject()
