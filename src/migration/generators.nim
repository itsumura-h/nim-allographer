import json, strformat
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

proc intGenerator*(name:string, nullable:bool, isDefault:bool,
                    default:int):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} INTEGER"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc blobGenerator*(name:string, nullable:bool):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} BLOB"

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isDefault:bool, 
                    default:bool):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} TINYINT"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc charGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} VARCHAR"
    if isDefault:
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

proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                        isDefault:bool, default:float):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} NUMERIC"
  elif driver == "mysql":
    result = &"{name} DECIMAL({maximum}, {digit})"
  
  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc floatGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isDefault:bool, default:float):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} FLOAT"
  elif driver == "mysql":
    result = &"{name} DOUBLE ({maximum}, {digit})"
  
  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool, isDefault:bool, 
                    default:string):string =
  let driver = util.getDriver()
  if driver == "sqlite":
    result = &"{name} VARCHAR"
  elif driver == "mysql":
    result = &"{name} ENUM"
  elif driver == "postgres":
    result = &"{name} ENUM"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

proc enumOptionsGenerator*(options:varargs[JsonNode]):string =
  var optionStrings = ""
  for i, option in options:
    if i > 0:
      optionStrings.add(", ")

    optionStrings.add($option)

  echo optionStrings