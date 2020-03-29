import json, strformat
import ../column

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"`{name}` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

proc intGenerator*(name:string, nullable:bool, isUnique:bool,
                    isDefault:bool, default:int, isUnsigned:bool):string =
  result = &"`{name}` INT"

  if isUnsigned:
    result.add(" UNSIGNED")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc smallIntGenerator*(name:string, nullable:bool, isUnique:bool,
                        isDefault:bool, default:int, isUnsigned:bool):string =
    result = &"`{name}` SMALLINT"

    if isUnsigned:
      result.add(" UNSIGNED")

    if isDefault:
      result.add(&" DEFAULT {default}")

    if not nullable:
      result.add(" NOT NULL")

    if isUnique:
      result.add(" UNIQUE")

proc mediumIntGenerator*(name:string, nullable:bool, isUnique:bool,
                        isDefault:bool, default:int, isUnsigned:bool):string =
    result = &"`{name}` MEDIUMINT"

    if isUnsigned:
      result.add(" UNSIGNED")

    if isDefault:
      result.add(&" DEFAULT {default}")

    if not nullable:
      result.add(" NOT NULL")

    if isUnique:
      result.add(" UNIQUE")

proc bigIntGenerator*(name:string, nullable:bool, isUnique:bool,
                      isDefault:bool, default:int, isUnsigned:bool):string =
    result = &"`{name}` BIGINT"

    if isUnsigned:
      result.add(" UNSIGNED")

    if isDefault:
      result.add(&" DEFAULT {default}")

    if not nullable:
      result.add(" NOT NULL")

    if isUnique:
      result.add(" UNIQUE")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isUnique:bool, isDefault:bool, default:float,
                      isUnsigned:bool):string =
  result = &"`{name}` DECIMAL({maximum}, {digit})"

  if isUnsigned:
      result.add(" UNSIGNED")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc doubleGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isUnique:bool, isDefault:bool, default:float,
                      isUnsigned:bool):string =
  result = &"`{name}` DOUBLE({maximum}, {digit})"

  if isUnsigned:
      result.add(" UNSIGNED")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc floatGenerator*(name:string, nullable:bool, isUnique:bool,
                      isDefault:bool, default:float, isUnsigned:bool):string =
  result = &"`{name}` DOUBLE"

  if isUnsigned:
    result.add(" UNSIGNED")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")
# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isUnique:bool,
                    isDefault:bool, default:string):string =
  result = &"`{name}` CHAR({maxLength})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc stringGenerator*(name:string, maxLength:int, nullable:bool, isUnique:bool,
                    isDefault:bool, default:string):string =
  result = &"`{name}` VARCHAR({maxLength})"

  if isDefault:
    result.add(
      &" DEFAULT '{default}'"
    )

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc textGenerator*(name:string, nullable:bool):string =
  result = &"`{name}` TEXT"

  if not nullable:
    result.add(" NOT NULL")

proc mediumTextGenerator*(name:string, nullable:bool):string =
  result = &"`{name}` MEDIUMTEXT"

  if not nullable:
    result.add(" NOT NULL")

proc longTextGenerator*(name:string, nullable:bool):string =
  result = &"`{name}` LONGTEXT"

  if not nullable:
    result.add(" NOT NULL")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(name:string, nullable:bool, isUnique:bool, isDefault:bool):string =
  result = &"`{name}` DATE"

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

proc datetimeGenerator*(name:string, nullable:bool, isUnique:bool, isDefault:bool):string =
  result = &"`{name}` DATETIME"

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

proc timeGenerator*(name:string, nullable:bool, isUnique:bool, isDefault:bool):string =
  result = &"`{name}` TIME"

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

proc timestampGenerator*(name:string, nullable:bool, isUnique:bool, isDefault:bool):string =
  result = &"`{name}` DATETIME"

  if not nullable:
      result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

proc timestampsGenerator*():string =
  result = "`created_at` DATETIME, "
  result.add("`updated_at` DATETIME DEFAULT (NOW())")

proc softDeleteGenetator*():string =
  result = "`deleted_at` DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, nullable:bool):string =
  result = &"`{name}` BLOB"

  if not nullable:
    result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isUnique:bool,
                    isDefault:bool, default:bool):string =
  # result = &"`{name}` TINYINT(1)"
  result = &"`{name}` BOOLEAN"

  if isDefault:
    let defaultInt = if default: 1 else: 0
    result.add(&" DEFAULT {defaultInt}")

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(", ")
    optionsString.add(
      &"'{option.getStr}'"
    )

  return optionsString

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool,
                    isUnique:bool):string =
  let optionsString = enumOptionsGenerator(name, options)
  result = &"`{name}` ENUM({optionsString})"

  if not nullable:
    result.add(" NOT NULL")

  if isUnique:
    result.add(" UNIQUE")

proc jsonGenerator*(name:string, nullable:bool):string =
  result = &"`{name}` JSON"

  if not nullable:
    result.add(" NOT NULL")

proc foreignColumnGenerator*(name:string):string =
  result = &"`{name}` BIGINT"

proc foreignGenerator*(name:string, table:string, column:string,
                        foreignOnDelete:ForeignOnDelete):string =
  var onDeleteString = "RESTRICT"
  if foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"


  result = &", FOREIGN KEY(`{name}`) REFERENCES {table}({column})"
  result.add(&" ON DELETE {onDeleteString}")
