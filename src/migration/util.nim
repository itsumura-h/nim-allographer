import os, parsecfg

proc getDriver*():string =
  let confPath = getCurrentDir() & "/config/database.ini"
  let conf = loadConfig(confPath)
  let driver = conf.getSectionValue("Connection", "driver")
  return driver
