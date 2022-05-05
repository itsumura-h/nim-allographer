import json, strformat, strutils
import ../../../async/database/base
import ../../../utils
import ../../grammers


# =============================================================================
# int
# =============================================================================
proc serialGenerator*(column:Column):string =
  result = &"'{column.name}' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"

proc intGenerator*(column:Column):string =
  result = &"'{column.name}' INTEGER"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(column:Column):string =
  result = &"'{column.name}' NUMERIC"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc floatGenerator*(column:Column):string =
  result = &"'{column.name}' REAL"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

# =============================================================================
# char
# =============================================================================
proc charGenerator*(column:Column):string =
  result = &"'{column.name}' VARCHAR"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  result.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc varcharGenerator*(column:Column):string =
  result = &"'{column.name}' VARCHAR"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  result.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc textGenerator*(column:Column):string =
  result = &"'{column.name}' TEXT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(column:Column):string =
  result = &"'{column.name}' DATE"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc datetimeGenerator*(column:Column):string =
  result = &"'{column.name}' DATETIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc timeGenerator*(column:Column):string =
  result = &"'{column.name}' TIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc timestampGenerator*(column:Column):string =
  result = &"'{column.name}' DATETIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc timestampsGenerator*(column:Column):string =
  result = "'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP, "
  result.add("'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP")

proc softDeleteGenerator*(column:Column):string =
  result = "'deleted_at' DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(column:Column):string =
  result = &"'{column.name}' BLOB"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

proc boolGenerator*(column:Column):string =
  result = &"'{column.name}' TINYINT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    raise newException(DbError, "unsigned is not allowed for bool in sqlite")

proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option}'"
    )

  return optionsString

proc enumGenerator*(column:Column):string =
  result = &"'{column.name}' VARCHAR"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsGenerator(column.name, options)
  result.add(&" CHECK ({optionsString})")

  if column.isUnsigned:
    raise newException(DbError, "unsigned is not allowed for enum in sqlite")

proc jsonGenerator*(column:Column):string =
  result = &"'{column.name}' TEXT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} > 0)")

# =============================================================================
# foreign key
# =============================================================================
proc foreignColumnGenerator*(column:Column):string =
  result = &"'{column.name}' INTEGER"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

proc strForeignColumnGenerator*(column:Column):string =
  result = &"'{column.name}' VARCHAR"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")

proc foreignGenerator*(column:Column):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let tableName = column.info["table"].getStr
  let columnnName = column.info["column"].getStr
  return &"FOREIGN KEY('{column.name}') REFERENCES {tableName}({columnnName}) ON DELETE {onDeleteString}"

proc alterAddForeignGenerator*(column:Column):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let tableName = column.info["table"].getStr
  let columnName = column.info["column"].getStr

  return &"REFERENCES {tableName}({columnName}) ON DELETE {onDeleteString}"


proc indexName*(table, column:string):string =
  let smallTable = table.toLowerAscii()
  return &"{smallTable}_{column}_index"
