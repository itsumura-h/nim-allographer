import json, strformat
import ../util

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"{name} INTEGER PRIMARY KEY"

proc intGenerator*(name:string, nullable:bool, isDefault:bool,
                    default:int, isUnsigned:bool):string =
  result = &"{name} INTEGER"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} >= 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} >= 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                        isDefault:bool, default:float,
                        isUnsigned:bool):string =
  result = &"{name} NUMERIC"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} >= 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} >= 0)")

proc floatGenerator*(name:string, nullable:bool, isDefault:bool,
                      default:float, isUnsigned:bool):string =
  result = &"{name} FLOAT"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} >= 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} >= 0)")
# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"{name} VARCHAR"
  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  result.add(&" CHECK (length({name}) <= {maxLength})")

proc varcharGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"{name} VARCHAR"
  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  result.add(&" CHECK (length({name}) <= {maxLength})")

proc textGenerator*(name:string, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"{name} TEXT"
  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(name:string, nullable:bool):string =
  result = &"{name} DATE"

  if not nullable:
    result.add(" NOT NULL")

proc datetimeGenerator*(name:string, nullable:bool):string =
  result = &"{name} DATETIME"

  if not nullable:
    result.add(" NOT NULL")
# =============================================================================
# others
# =============================================================================
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

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0:
      optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option.getStr}'"
    )
  
  return optionsString

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool,
                    isDefault:bool, default:string):string =
  result = &"{name} VARCHAR"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  let optionsString = enumOptionsGenerator(name, options)
  result.add(
    &" CHECK ({optionsString})"
  )
