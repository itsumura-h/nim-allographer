import strformat
import util


proc getCharset*():string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = ""
  elif driver == "mysql":
    result = &" DEFAULT CHARSET=utf8mb4"
  elif driver == "postgres":
    result = ""


# ==================== generate querty ====================

proc serialGenerator*(name:string):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} INTEGER PRIMARY KEY"
  elif driver == "mysql":
    result = &"{name} BIGMINT NOT NULL AUTO_INCREMENT"
  elif driver == "postgres":
    result = &"{name} serial PRIMARY KEY"

proc intGenerator*(name:string, nullable:bool, default:string):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} INTEGER"

  if default != "default_value":
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, default:string):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} TINYINT"

  if default == "false":
    result.add(
      &" DEFAULT 0"
    )
  elif default == "true":
    result.add(
      &" DEFAULT 1"
    )

  if not nullable:
    result.add(" NOT NULL")

proc blobGenerator*(name:string, nullable:bool):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} BLOB"

  if not nullable:
    result.add(" NOT NULL")

proc charGenerator*(name:string, maxLength:int, nullable:bool,
                    default:string):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} VARCHAR"
    if default != "default_value":
      result.add(
        &" DEFAULT '{default}'"
      )

  if not nullable:
    result.add(" NOT NULL")

proc dateGenerator*(name:string, nullable:bool):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} DATE"

  if not nullable:
    result.add(" NOT NULL")

proc datetimeGenerator*(name:string, nullable:bool):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} DATETIME"

  if not nullable:
    result.add(" NOT NULL")