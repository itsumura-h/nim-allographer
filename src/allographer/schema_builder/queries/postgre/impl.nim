import json, strformat, strutils, sequtils
import ../../../async/database/base
import ../../../utils
import ../../grammers
import ../generator_utils

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE SERIAL NOT NULL PRIMARY KEY"
  else:
    result = &"\"{column.name}\" SERIAL NOT NULL PRIMARY KEY"

proc intGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE INTEGER"
  else:
    result = &"\"{column.name}\" INTEGER"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

proc smallIntGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE SMALLINT"
  else:
    result = &"\"{column.name}\" SMALLINT"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

proc mediumIntGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE INTEGER"
  else:
    result = &"\"{column.name}\" INTEGER"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

proc bigIntGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE BIGINT"
  else:
    result = &"\"{column.name}\" BIGINT"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(column:Column, table:Table, isAlter=false):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  if isAlter:
    result = &"\"{column.name}\" TYPE NUMERIC({maximum}, {digit})"
  else:
    result = &"\"{column.name}\" NUMERIC({maximum}, {digit})"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

proc doubleGenerator*(column:Column, table:Table, isAlter=false):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  if isAlter:
    result = &"\"{column.name}\" TYPE NUMERIC({maximum}, {digit})"
  else:
    result = &"\"{column.name}\" NUMERIC({maximum}, {digit})"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

proc floatGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE NUMERIC"
  else:
    result = &"\"{column.name}\" NUMERIC"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" > 0)")

# =============================================================================
# char
# =============================================================================
proc charGenerator*(column:Column, table:Table, isAlter=false):string =
  let maxLength = column.info["maxLength"].getInt
  if isAlter:
    result = &"\"{column.name}\" TYPE CHAR({maxLength})"
  else:
    result = &"\"{column.name}\" CHAR({maxLength})"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "char")

proc stringGenerator*(column:Column, table:Table, isAlter=false):string =
  let maxLength = column.info["maxLength"].getInt
  if isAlter:
    result = &"\"{column.name}\" TYPE VARCHAR({maxLength})"
  else:
    result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "string")

proc textGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE TEXT"
  else:
    result = &"\"{column.name}\" TEXT"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "text")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE DATE"
  else:
    result = &"\"{column.name}\" DATE"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date")

proc datetimeGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE TIMESTAMP"
  else:
    result = &"\"{column.name}\" TIMESTAMP"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date")

proc timeGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE TIME"
  else:
    result = &"\"{column.name}\" TIME"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date")

proc timestampGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE TIMESTAMP"
  else:
    result = &"\"{column.name}\" TIMESTAMP"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date")

proc timestampsGenerator*(column:Column, table:Table):string =
  result = "\"created_at\" TIMESTAMP, "
  result.add("\"updated_at\" TIMESTAMP DEFAULT (NOW())")

proc softDeleteGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = "\"deleted_at\" TYPE TIMESTAMP"
  else:
    result = "\"deleted_at\" TIMESTAMP"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE BYTEA"
  else:
    result = &"\"{column.name}\" BYTEA"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "blob")

proc boolGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE BOOLEAN"
  else:
    result = &"\"{column.name}\" BOOLEAN"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowed("unsigned", "bool")

proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option}'"
    )

  return optionsString

proc enumGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE CHARACTER"
  else:
    result = &"\"{column.name}\" CHARACTER"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "text")

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsGenerator(column.name, options)
  result.add(&" CHECK ({optionsString})")

proc jsonGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE JSON"
  else:
    result = &"\"{column.name}\" JSON"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if column.isUnique:
    notAllowed("unique", "json")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowed("unsigned", "json")

proc foreignColumnGenerator*(column:Column, table:Table, isAlter=false):string =
  if isAlter:
    result = &"\"{column.name}\" TYPE INT"
  else:
    result = &"\"{column.name}\" INT"
  
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

proc strForeignColumnGenerator*(column:Column, table:Table, isAlter=false):string =
  let maxLength = column.info["maxLength"].getInt
  if isAlter:
    result = &"\"{column.name}\" TYPE VARCHAR({maxLength})"
  else:
    result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")

proc foreignGenerator*(column:Column, table:Table, isAlter=false):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let refColumn = column.info["column"].getStr
  var refTable = column.info["table"].getStr
  pgWrapUpper(refTable)
  return &"FOREIGN KEY(\"{column.name}\") REFERENCES {refTable}({refColumn}) ON DELETE {onDeleteString}"

proc alterAddForeignGenerator*(column:Column, table:Table, isAlter=false):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  var constraintName = &"{table.name}_{column.name}"
  pgWrapUpper(constraintName)
  let refColumn = column.info["column"].getStr
  var refTable = column.info["table"].getStr
  pgWrapUpper(refTable)
  return &"CONSTRAINT {constraintName} FOREIGN KEY (\"{column.name}\") REFERENCES {refTable} ({refColumn}) ON DELETE {onDeleteString}"

proc alterDeleteGenerator*(column:Column, table:Table, isAlter=false):string =
  var tableName = table.name
  pgWrapUpper(tableName)
  return &"ALTER TABLE {tableName} DROP {column.name}"

proc alterDeleteForeignGenerator*(column:Column, table:Table, isAlter=false):string =
  var constraintName = &"{table.name}_{column.name}"
  pgWrapUpper(constraintName)
  var tableName = table.name
  pgWrapUpper(tableName)
  return &"ALTER TABLE {tableName} DROP CONSTRAINT {constraintName}"

proc indexGenerate*(column:Column, table:Table, isAlter=false):string =
  var tableName = table.name
  let smallTable = tableName.toLowerAscii()
  pgWrapUpper(tableName)
  return &"CREATE INDEX {smallTable}_{column.name}_index ON {tableName}({column.name})"
