import os, parsecfg

proc getDriver*():string =
  let confPath = getCurrentDir() & "/config/database.ini"
  let conf = loadConfig(confPath)
  let driver = conf.getSectionValue("Connection", "driver")
  return driver

proc logger*(output: any) =
  # get Config file
  let confPath = getCurrentDir() & "/config/database.ini"

  var conf = loadConfig(confPath)
  var isDisplayString = conf.getSectionValue("Log", "display")
  if isDisplayString == "true":
    echo $output