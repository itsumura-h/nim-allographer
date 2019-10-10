import os, parsecfg, strformat

proc getDriver*():string =
  let confPath = getCurrentDir() & "/config/database.ini"
  let conf = loadConfig(confPath)
  let driver = conf.getSectionValue("Connection", "driver")
  return driver

proc getCharset*():string =
  let driver = getDriver()
  if driver == "sqlite":
    result = ""
  elif driver == "mysql":
    result = &"DEFAULT CHARSET=utf8mb4"
  elif driver == "postgres":
    result = ""


# ==================== generate querty ====================

proc serialGenerator*(name:string):string =
  let driver = getDriver()
  if driver == "sqlite":
    result = &"{name} INTEGER PRIMARY KEY"
  elif driver == "mysql":
    result = &"{name} BIGMINT NOT NULL AUTO_INCREMENT"
  elif driver == "postgres":
    result = &"{name} serial PRIMARY KEY"

proc intGenerator*(name:string, notNull:bool):string =
  let driver = getDriver()
  if driver == "sqlite":
    result = &"{name} INTEGER"

  if notNull:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, notNull:bool):string =
  let driver = getDriver()
  if driver == "sqlite":
    result = &"{name} TINYINT"

  if notNull:
    result.add(" NOT NULL")

proc blobGenerator*(name:string, notNull:bool):string =
  let driver = getDriver()
  if driver == "sqlite":
    result = &"{name} BLOB"

  if notNull:
    result.add(" NOT NULL")

proc charGenerator*(name:string, maxLength:int, notNull:bool,
                    default:seq[string]):string =
  let driver = getDriver()
  if driver == "sqlite":
    result = &"{name} VARCHAR"
    if default.len > 0:
      result.add(&" DEFAULT '{default[0]}'")

  if notNull:
    result.add(" NOT NULL")

proc dateGenerator*(name:string, notNull:bool):string =
  let driver = getDriver()
  if driver == "sqlite":
    result = &"{name} DATE"

  if notNull:
    result.add(" NOT NULL")
