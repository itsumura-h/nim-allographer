import json
import async/async_db

import os, strutils
import dotenv

for f in walkDir(getCurrentDir()):
  if f.path.split("/")[^1] == ".env":
    load(getCurrentDir(), ".env")
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
