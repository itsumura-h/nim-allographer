import std/os
import std/strutils
import std/streams
import std/parsecfg

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


const
  isExistsSqlite* = getEnv("DB_SQLITE", $false).parseBool
  isExistsPostgres* = getEnv("DB_POSTGRES", $false).parseBool
  isExistsMysql* = getEnv("DB_MYSQL", $false).parseBool
  isExistsMariadb* = getEnv("DB_MARIADB", $false).parseBool
  isExistsSurrealdb* = getEnv("DB_SURREAL", $false).parseBool
