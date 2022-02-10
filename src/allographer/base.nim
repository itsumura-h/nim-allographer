import os, strutils, json, streams, parsecfg
import async/async_db

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
  Rdb* = ref object
    conn*: Connections
    log*: LogSetting
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]
