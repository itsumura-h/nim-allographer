import os, parsecfg

var
  configFile* = getCurrentDir() / "/config/database.ini"

proc getDriver*():string =
  let conf = loadConfig(configFile)
  let driver = conf.getSectionValue("Connection", "driver")
  return driver

proc logger*(output: any) =
  # get Config file
  var conf = loadConfig(configFile)
  var isDisplayString = conf.getSectionValue("Log", "display")
  if isDisplayString == "true":
    echo $output
