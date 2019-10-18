import json, strformat
import ../util


proc serialGenerator*(name:string):string =
  result = &"{name} INTEGER PRIMARY KEY"

proc intGenerator*(name:string, nullable:bool, isDefault:bool,
                    default:int):string =
  result = &"{name} INTEGER"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc blobGenerator*(name:string, nullable:bool):string =
  result = &"{name} BLOB"

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isDefault:bool, 
                    default:bool):string =
  result = &"{name} TINYINT"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc charGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"{name} VARCHAR"
  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

proc dateGenerator*(name:string, nullable:bool):string =
  result = &"{name} DATE"

  if not nullable:
    result.add(" NOT NULL")

proc datetimeGenerator*(name:string, nullable:bool):string =
  result = &"{name} DATETIME"

  if not nullable:
    result.add(" NOT NULL")

proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                        isDefault:bool, default:float):string =
  result = &"{name} NUMERIC"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc floatGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isDefault:bool, default:float):string =
  result = &"{name} FLOAT"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionStrings = ""
  for i, option in options:
    if i > 0:
      optionStrings.add(" OR ")
    optionStrings.add(
      &"{name} = '{option.getStr}'"
    )
  
  return optionStrings

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool,
                    isDefault:bool, default:string):string =
  let optionsString = enumOptionsGenerator(name, options)
  result = &"{name} VARCHAR"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  result.add(
    &" CHECK ({optionsString})"
  )
