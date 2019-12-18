import os, parsecfg, terminal, logging, strutils
import connection

let logConfigFile* = getCurrentDir() & "/config/logging.ini"

proc getDriver*():string =
  return connection.DRIVER

proc driverTypeError*() =
  let driver = getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")

proc logger*(output: any) =
  # get Config file
  let conf = loadConfig(logConfigFile)
  # console log
  let isDisplayString = conf.getSectionValue("Log", "display")
  if isDisplayString == "true":
    let logger = newConsoleLogger()
    logger.log(lvlInfo, $output)
  # file log
  let isFileOutString = conf.getSectionValue("Log", "file")
  if isFileOutString == "true":
    let path = conf.getSectionValue("Log", "logDir") & "/log.log"
    createDir(parentDir(path))
    let logger = newRollingFileLogger(path, mode=fmAppend, fmtStr=verboseFmtStr)
    var newOutput = $output
    newOutput.removeSuffix
    logger.log(lvlInfo, newOutput)


proc echoErrorMsg*(msg:string) =
  styledWriteLine(stdout, fgRed, bgDefault, msg, resetStyle)
  # file log
  let conf = loadConfig(logConfigFile)
  let isFileOutString = conf.getSectionValue("Log", "file")
  if isFileOutString == "true":
    let path = conf.getSectionValue("Log", "logDir") & "/error.log"
    createDir(parentDir(path))
    let logger = newRollingFileLogger(path)
    logger.log(lvlInfo, msg)