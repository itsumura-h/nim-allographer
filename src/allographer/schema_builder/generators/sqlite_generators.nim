import json, strformat
import ../column
import ../../utils
from db_common import DbError

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"'{name}' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

proc intGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:int):string =
  result = &"'{name}' INTEGER"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, maximum:int, digit:int, nullable:bool,
                      isUnique:bool, isUnsigned:bool,
                      isDefault:bool, default:float):string =
  result = &"'{name}' NUMERIC"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc floatGenerator*(name:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool,default:float):string =
  result = &"'{name}' REAL"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, maxLength:int, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"'{name}' VARCHAR"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  result.add(&" CHECK (length('{name}') <= {maxLength})")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc varcharGenerator*(name:string, maxLength:int, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"'{name}' VARCHAR"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  result.add(&" CHECK (length('{name}') <= {maxLength})")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc textGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:string):string =
  result = &"'{name}' TEXT"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool):string =
  result = &"'{name}' DATE"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc datetimeGenerator*(name:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool, isDefault:bool):string =
  result = &"'{name}' DATETIME"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc timeGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool):string =
  result = &"'{name}' TIME"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc timestampGenerator*(name:string, nullable:bool, isUnique:bool,
                          isUnsigned:bool, isDefault:bool):string =
  result = &"'{name}' DATETIME"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc timestampsGenerator*():string =
  result = "'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP, "
  result.add("'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP")

proc softDeleteGenerator*():string =
  result = "'deleted_at' DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:string):string =
  result = &"'{name}' BLOB"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc boolGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:bool):string =
  result = &"'{name}' TINYINT"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    raise newException(DbError, "unsigned is not allowed for bool in sqlite")

proc enumOptionsGenerator(name:string, options:openArray[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option.getStr}'"
    )

  return optionsString

proc enumGenerator*(name:string, options:openArray[JsonNode],
                    nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:string):string =
  result = &"'{name}' VARCHAR"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  let optionsString = enumOptionsGenerator(name, options)
  result.add(&" CHECK ({optionsString})")

  if isUnsigned:
    raise newException(DbError, "unsigned is not allowed for enum in sqlite")

proc jsonGenerator*(name:string, nullable:bool, isUnique:bool, isUnsigned:bool,
                    isDefault:bool, default:JsonNode):string =
  result = &"'{name}' TEXT"

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default.pretty}'")

  if isUnsigned:
    result.add(&" CHECK ({name} > 0)")

proc foreignColumnGenerator*(name:string, isDefault:bool, default:int):string =
  result = &"'{name}' INTEGER"
  if isDefault:
    result.add(&" DEFAULT {default}")

proc foreignGenerator*(name:string, table:string, column:string,
                        foreignOnDelete:ForeignOnDelete):string =
  var onDeleteString = "RESTRICT"
  if foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  return &"FOREIGN KEY('{name}') REFERENCES {table}({column}) ON DELETE {onDeleteString}"

proc alterAddForeignGenerator*(table:string, column:string):string =
  return &"REFERENCES {table}({column})"


proc indexGenerate*(table, column:string):string =
  var table = table
  liteWrapUpper(table)
  return &"CREATE INDEX {column}_index ON {table}({column})"
