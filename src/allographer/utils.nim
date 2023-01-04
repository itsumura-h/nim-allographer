import std/os
import std/parsecfg
import std/terminal
import std/logging
import std/macros
import std/strformat
import std/strutils
import ./base


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
  

# var isUpper = false
# for c in input:
#   if c.isUpperAscii():
#     isUpper = true
#     break
# if isUpper:
#   input = &"\"{input}\""

proc liteQuoteSchema*(input:var string) =
  input = &"`{input}`"

proc myQuoteSchema*(input:var string) =
  input = &"`{input}`"

proc pgQuoteSchema*(input:var string) =
  input = &"\"{input}\""

proc quoteSchema*(input:var string, driver:Driver) =
  var isUpper = false
  for c in input:
    if c.isUpperAscii():
      isUpper = true
      break
  if isUpper:
    case driver:
    of SQLite3:
      liteQuoteSchema(input)
    of MySQL, MariaDB:
      myQuoteSchema(input)
    of PostgreSQL:
      pgQuoteSchema(input)


proc liteQuoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"`{c[0]}` as `{c[1]}`")
    else:
      tmp.add(&"`{row}`")
  input = tmp.join(".")

proc myQuoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"`{c[0]}` as `{c[1]}`")
    else:
      tmp.add(&"`{row}`")
  input = tmp.join(".")

proc pgQuoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"\"{c[0]}\" as \"{c[1]}\"")
    else:
      tmp.add(&"\"{row}\"")
  if tmp.len > 1:
    input = tmp.join(".")
  else:
    input = tmp[0]

proc quote*(input:var string, driver:Driver) =
  # var isUpper = false
  # for c in input:
  #   if c.isUpperAscii():
  #     isUpper = true
  #     break
  # if isUpper:
  #   case driver:
  #   of SQLite3:
  #     liteQuoteColumn(input)
  #   of MySQL, MariaDB:
  #     myQuoteColumn(input)
  #   of PostgreSQL:
  #     pgQuoteColumn(input)
  case driver:
  of SQLite3:
    liteQuoteColumn(input)
  of MySQL, MariaDB:
    myQuoteColumn(input)
  of PostgreSQL:
    pgQuoteColumn(input)
