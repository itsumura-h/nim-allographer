import json, strformat
import ../column

# =============================================================================
# int
# =============================================================================
proc incrementGenerator*(name:string):string =
  result = &"{name} INTEGER NOT NULL PRIMARY KEY"

proc intGenerator*(name:string, nullable:bool, isDefault:bool, default:int,
                    isUnsigned:bool):string =
  result = &"{name} INTEGER"

  if isDefault:
    result.add(&" DEFAULT {default}")
  
  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc smallIntGenerator*(name:string, nullable:bool, isDefault:bool, default:int,
                        isUnsigned:bool):string =
  result = &"{name} SMALLINT"

  if isDefault:
    result.add(&" DEFAULT {default}")
  
  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc mediumIntGenerator*(name:string, nullable:bool, isDefault:bool, default:int,
                          isUnsigned:bool):string =
  result = &"{name} INTEGER"

  if isDefault:
    result.add(&" DEFAULT {default}")
  
  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc bigIntGenerator*(name:string, nullable:bool, isDefault:bool, default:int,
                      isUnsigned:bool):string =
  result = &"{name} BIGINT"

  if isDefault:
    result.add(&" DEFAULT {default}")
  
  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isDefault:bool, default:float, isUnsigned:bool):string =
  result = &"{name} NUMERIC({maximum}, {digit})"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc doubleGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isDefault:bool, default:float, isUnsigned:bool):string =
  result = &"{name} NUMERIC({maximum}, {digit})"

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc floatGenerator*(name:string, nullable:bool, isDefault:bool, default:float,
                      isUnsigned:bool):string =
  result = &"{name} NUMERIC"
  # if isWithOption:
  #   result = &"{name} NUMERIC({maximum}, {digit})"
  # else:
  #   result = &"{name} NUMERIC"

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ({name} = null OR {name} > 0)")
  elif isUnsigned:
    result.add(&" CHECK ({name} > 0)")
# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"{name} CHAR({maxLength})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

proc stringGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"{name} VARCHAR({maxLength})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

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
proc dateGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"{name} DATE"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc datetimeGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"{name} TIMESTAMP"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc timeGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"{name} TIME"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc timestampGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"{name} TIMESTAMP"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (NOW())"
    )

proc timestampsGenerator*():string =
  result = "created_at TIMESTAMP, "
  result.add("updated_at TIMESTAMP DEFAULT (NOW())")

proc softDeleteGenetator*():string =
  result = "deleted_at TIMESTAMP"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, nullable:bool):string =
  result = &"{name} BYTEA"

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isDefault:bool, 
                    default:bool):string =
  result = &"{name} BOOLEAN"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option.getStr}'"
    )

  return optionsString

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool,
                    isDefault:bool, default:string):string =
  result = &"{name} CHARACTER"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  let optionsString = enumOptionsGenerator(name, options)
  if nullable:
    result.add(&" CHECK ({name} = null OR {optionsString})")
  else:
    result.add(&" CHECK ({optionsString})")

proc jsonGenerator*(name:string, nullable:bool):string =
  result = &"{name} JSON"

  if not nullable:
    result.add(" NOT NULL")

proc foreignColumnGenerator*(name:string):string =
  result = &"{name} INT"

proc foreignGenerator*(name:string, table:string, column:string,
                        foreignOnDelete:ForeignOnDelete):string =
  var onDeleteString = "RESTRICT"
  if foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"


  result = &", FOREIGN KEY({name}) REFERENCES {table}({column})"
  result.add(&" ON DELETE {onDeleteString}")
