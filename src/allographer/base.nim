import
  std/os,
  std/strutils,
  std/json,
  std/streams,
  std/parsecfg,
  ./async/database/base


for f in walkDir(getCurrentDir()):
  if f.path.split("/")[^1] == ".env":
    let path = getCurrentDir() / ".env"
    var f = newFileStream(path, fmRead)
    var p: CfgParser
    open(p, f, path)
    while true:
      let e = next(p)
      case e.kind
      of cfgEof: break
      of cfgKeyValuePair: putEnv(e.key, e.value)
      else: discard
    break

type
  LogSetting* = ref object
    shouldDisplayLog*: bool
    shouldOutputLogFile*: bool
    logDir*: string
  Driver* = enum
    MySQL
    MariaDB
    PostgreSQL
    SQLite3
  Rdb* = ref object
    driver*: Driver
    conn*: Connections
    log*: LogSetting
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]
    # for transaction
    isInTransaction*:bool
    transactionConn*:int
