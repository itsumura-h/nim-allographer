import json, strformat
import ../column

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"'{name}' INTEGER PRIMARY KEY"

proc intGenerator*(name:string, nullable:bool, isDefault:bool,
                    default:int, isUnsigned:bool):string =
  result = &"'{name}' INTEGER"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ('{name}' = null OR '{name}' > 0)")
  elif isUnsigned:
    result.add(&" CHECK ('{name}' > 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                        isDefault:bool, default:float,
                        isUnsigned:bool):string =
  result = &"'{name}' NUMERIC"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ('{name}' = null OR '{name}' > 0)")
  elif isUnsigned:
    result.add(&" CHECK ('{name}' > 0)")

proc floatGenerator*(name:string, nullable:bool, isDefault:bool,
                      default:float, isUnsigned:bool):string =
  result = &"'{name}' DOUBLE"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

  if nullable and isUnsigned:
    result.add(&" CHECK ('{name}' = null OR '{name}' > 0)")
  elif isUnsigned:
    result.add(&" CHECK ('{name}' > 0)")
# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"'{name}' VARCHAR"
  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  result.add(&" CHECK (length('{name}') <= {maxLength})")

proc varcharGenerator*(name:string, maxLength:int, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"'{name}' VARCHAR"
  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  result.add(&" CHECK (length('{name}') <= {maxLength})")

proc textGenerator*(name:string, nullable:bool, isDefault:bool,
                    default:string):string =
  result = &"'{name}' TEXT"
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
  result = &"'{name}' DATE"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (DATE('now','localtime'))"
    )

proc datetimeGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"'{name}' DATETIME"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (DATETIME('now','localtime'))"
    )

proc timeGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"'{name}' TIME"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (TIME('now','localtime'))"
    )

proc timestampGenerator*(name:string, nullable:bool, isDefault:bool):string =
  result = &"'{name}' DATETIME"

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(
      &" DEFAULT (DATETIME('now','localtime'))"
    )

proc timestampsGenerator*():string =
  result = "created_at DATETIME, "
  result.add("updated_at DATETIME DEFAULT (DATETIME('now','localtime'))")

proc softDeleteGenerator*():string =
  result = "deleted_at DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, nullable:bool):string =
  result = &"'{name}' BLOB"

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isDefault:bool, 
                    default:bool):string =
  result = &"'{name}' TINYINT"

  if isDefault:
    result.add(
      &" DEFAULT {default}"
    )

  if not nullable:
    result.add(" NOT NULL")

proc enumOptionsGenerator(name:string, options:openArray[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"'{name}' = '{option.getStr}'"
    )
  
  return optionsString

proc enumGenerator*(name:string, options:openArray[JsonNode], nullable:bool,
                    isDefault:bool, default:string):string =
  result = &"'{name}' VARCHAR"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  let optionsString = enumOptionsGenerator(name, options)
  if nullable:
    result.add(&" CHECK ('{name}' = null OR {optionsString})")
  else:
    result.add(&" CHECK ({optionsString})")

proc jsonGenerator*(name:string, nullable:bool):string =
  result = &"'{name}' TEXT"

  if not nullable:
    result.add(" NOT NULL")

proc foreignColumnGenerator*(name:string):string =
  result = &"'{name}' INTEGER"

proc foreignGenerator*(name:string, table:string, column:string,
                        foreignOnDelete:ForeignOnDelete):string =
  var onDeleteString = "RESTRICT"
  if foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  result = &", FOREIGN KEY('{name}') REFERENCES {table}({column})"
  result.add(&" ON DELETE {onDeleteString}")