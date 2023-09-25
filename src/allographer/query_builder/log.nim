import std/os
import std/parsecfg
import std/terminal
import std/logging
import std/macros
import std/strformat


type
  LogSetting* = ref object
    shouldDisplayLog*: bool
    shouldOutputLogFile*: bool
    logDir*: string

proc logger*(self:LogSetting, output: auto) =
  # let msg = $output & " " & $args
  let msg = $output
  # console log
  if self.shouldDisplayLog:
    let logger = newConsoleLogger()
    logger.log(lvlDebug, msg)
  # file log
  if self.shouldOutputLogFile:
    # info $output & $args
    let path = self.logDir & "/log.log"
    createDir(parentDir(path))
    let logger = newRollingFileLogger(path, mode=fmAppend, fmtStr=verboseFmtStr)
    defer: logger.file.close()
    logger.log(lvlDebug, msg)
    flushFile(logger.file)


proc echoErrorMsg*(self:LogSetting, msg:string, args:seq[string] = @[]) =
  let msg = msg & " " & $args
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
