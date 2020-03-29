import json, strformat
import ../column
from db_common import DbError


proc notAllowed(option:string, typ:string) =
  raise newException(DbError, &"{option} is not allowed in {typ} column")
# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"`{name}` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

proc intGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:int):string =
  result = &"`{name}` INT"

  if isUnsigned:
    result.add(" UNSIGNED")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

proc smallIntGenerator*(name:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool, isDefault:bool, default:int):string =
    result = &"`{name}` SMALLINT"

    if isUnsigned:
      result.add(" UNSIGNED")

    if isUnique:
      result.add(" UNIQUE")

    if isDefault:
      result.add(&" DEFAULT {default}")

    if not nullable:
      result.add(" NOT NULL")

proc mediumIntGenerator*(name:string, nullable:bool, isUnique:bool,
                         isUnsigned:bool, isDefault:bool, default:int):string =
    result = &"`{name}` MEDIUMINT"

    if isUnsigned:
      result.add(" UNSIGNED")

    if isUnique:
      result.add(" UNIQUE")

    if isDefault:
      result.add(&" DEFAULT {default}")

    if not nullable:
      result.add(" NOT NULL")

proc bigIntGenerator*(name:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:int):string =
    result = &"`{name}` BIGINT"

    if isUnsigned:
      result.add(" UNSIGNED")

    if isUnique:
      result.add(" UNIQUE")

    if isDefault:
      result.add(&" DEFAULT {default}")

    if not nullable:
      result.add(" NOT NULL")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isUnique:bool,  isUnsigned:bool,
                      isDefault:bool, default:float):string =
  result = &"`{name}` DECIMAL({maximum}, {digit})"

  if isUnsigned:
    result.add(" UNSIGNED")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

proc doubleGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isUnique:bool, isUnsigned:bool,
                      isDefault:bool, default:float):string =
  result = &"`{name}` DOUBLE({maximum}, {digit})"

  if isUnsigned:
    result.add(" UNSIGNED")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

proc floatGenerator*(name:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:float):string =
  result = &"`{name}` DOUBLE"

  if isUnsigned:
    result.add(" UNSIGNED")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if not nullable:
    result.add(" NOT NULL")

# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isUnique:bool,
                     isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"`{name}` CHAR({maxLength})"

  if isUnsigned:
    notAllowed("unsigned", "char")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if not nullable:
    result.add(" NOT NULL")

proc stringGenerator*(name:string, maxLength:int, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"`{name}` VARCHAR({maxLength})"

  if isUnsigned:
    notAllowed("unsigned", "string")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if not nullable:
    result.add(" NOT NULL")

proc textGenerator*(name:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"`{name}` TEXT"

  if isUnsigned:
    notAllowed("unsigned", "text")

  if isUnique:
    notAllowed("unique", "text")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if not nullable:
    result.add(" NOT NULL")

proc mediumTextGenerator*(name:string, nullable:bool, isUnique:bool,
                          isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"`{name}` MEDIUMTEXT"

  if isUnsigned:
    notAllowed("unsigned", "medium text")

  if isUnique:
    notAllowed("unique", "medium text")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if not nullable:
    result.add(" NOT NULL")

proc longTextGenerator*(name:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"`{name}` LONGTEXT"

  if isUnsigned:
    notAllowed("unsigned", "long text")

  if isUnique:
    notAllowed("unique", "long text")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if not nullable:
    result.add(" NOT NULL")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool):string =
  result = &"`{name}` DATE"

  if isUnsigned:
    notAllowed("unsigned", "date")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

proc datetimeGenerator*(name:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool,isDefault:bool):string =
  result = &"`{name}` DATETIME"

  if isUnsigned:
    notAllowed("unsigned", "datetime")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if not nullable:
    result.add(" NOT NULL")

proc timeGenerator*(name:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool):string =
  result = &"`{name}` TIME"

  if isUnsigned:
    notAllowed("unsigned", "time")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if not nullable:
    result.add(" NOT NULL")

proc timestampGenerator*(name:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool, isDefault:bool):string =
  result = &"`{name}` DATETIME"

  if isUnsigned:
    notAllowed("unsigned", "timestamp")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if not nullable:
      result.add(" NOT NULL")

proc timestampsGenerator*():string =
  result = "`created_at` DATETIME, "
  result.add("`updated_at` DATETIME DEFAULT (NOW())")

proc softDeleteGenetator*():string =
  result = "`deleted_at` DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"`{name}` BLOB"

  if isUnsigned:
    notAllowed("unsigned", "blob")

  if isUnique:
    notAllowed("unique", "blob")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if not nullable:
      result.add(" NOT NULL")

proc boolGenerator*(name:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:bool):string =
  result = &"`{name}` BOOLEAN"

  if isUnsigned:
    notAllowed("unsigned", "bool")

  if isUnique:
    result.add(" UNIQUE")

  if isDefault:
    let defaultInt = if default: 1 else: 0
    result.add(&" DEFAULT {defaultInt}")

  if not nullable:
      result.add(" NOT NULL")

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(", ")
    optionsString.add(
      &"'{option.getStr}'"
    )

  return optionsString

proc enumGenerator*(name:string, options:varargs[JsonNode], nullable:bool,
                    isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:string):string =
  let optionsString = enumOptionsGenerator(name, options)
  result = &"`{name}` ENUM({optionsString})"

  if isUnsigned:
    notAllowed("unsigned", "enum")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

proc jsonGenerator*(name:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool):string =
  result = &"`{name}` JSON"

  if isUnsigned:
    notAllowed("unsigned", "json")

  if isUnique:
    notAllowed("unique", "json")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    notAllowed("default value", "json")

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
