import os, parsecfg, terminal, logging, macros, strformat, strutils
# self
import ./base

# proc driverTypeError*(driver:string) =
#   if driver != "sqlite" and driver != "mysql" and driver != "mariadb" and driver != "postgres":
#     raise newException(OSError, "invalid DB driver type")


proc logger*(self:LogSetting, output: auto, args:varargs[string]) =
  # console log
  if self.shouldDisplayLog:
    let logger = newConsoleLogger()
    logger.log(lvlDebug, $output & " " & $args)
  # file log
  if self.shouldOutputLogFile:
    # info $output & $args
    let path = self.logDir & "/log.log"
    createDir(parentDir(path))
    let logger = newRollingFileLogger(path, mode=fmAppend, fmtStr=verboseFmtStr)
    defer: logger.file.close()
    logger.log(lvlDebug, $output & " " & $args)
    flushFile(logger.file)


proc echoErrorMsg*(self:LogSetting, msg:string) =
  # console log
  if self.shouldDisplayLog:
    styledWriteLine(stdout, fgRed, bgDefault, msg, resetStyle)
  # file log
  if self.shouldOutputLogFile:
    let path = self.logDir & "/error.log"
    createDir(parentDir(path))
    let logger = newRollingFileLogger(path, mode=fmAppend, fmtStr=verboseFmtStr)
    defer: logger.file.close()
    logger.log(lvlError, msg)
    flushFile(logger.file)

proc echoWarningMsg*(self:LogSetting, msg:string) =
  # console log
  if self.shouldDisplayLog:
    styledWriteLine(stdout, fgYellow, bgDefault, msg, resetStyle)
  # file log
  if self.shouldOutputLogFile:
    let path = self.logDir & "/error.log"
    createDir(parentDir(path))
    let logger = newRollingFileLogger(path, mode=fmAppend, fmtStr=verboseFmtStr)
    defer: logger.file.close()
    logger.log(lvlError, msg)
    flushFile(logger.file)
  

proc liteWrapUpper*(input:var string) =
  var isUpper = false
  for c in input:
    if c.isUpperAscii():
      isUpper = true
      break
  if isUpper:
    input = &"\"{input}\""

proc myWrapUpper*(input:var string) =
  var isUpper = false
  for c in input:
    if c.isUpperAscii():
      isUpper = true
      break
  if isUpper:
    input = &"`{input}`"

proc pgWrapUpper*(input:var string) =
  var isUpper = false
  for c in input:
    if c.isUpperAscii():
      isUpper = true
      break
  if isUpper:
    input = &"\"{input}\""

proc wrapUpper*(input:var string, driver:Driver) =
  case driver:
  of SQLite3:
    liteWrapUpper(input)
  of MySQL, MariaDB:
    myWrapUpper(input)
  of PostgreSQL:
    pgWrapUpper(input)
