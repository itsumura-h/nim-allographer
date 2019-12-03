import os, parsecfg, terminal

var
  configFile* = getCurrentDir() & "/config/database.ini"

proc getDriver*():string =
  let conf = loadConfig(configFile)
  let driver = conf.getSectionValue("Connection", "driver")
  return driver

proc driverTypeError*() =
  let driver = getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")

proc logger*(output: any) =
  # get Config file
  var conf = loadConfig(configFile)
  var isDisplayString = conf.getSectionValue("Log", "display")
  if isDisplayString == "true":
    echo $output

proc echoErrorMsg*(msg:string) =
  styledWriteLine(stdout, fgRed, bgDefault, msg, resetStyle)