import json, strformat
import ../column
import generator_util
import ../../utils

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(name:string):string =
  result = &"\"{name}\" SERIAL NOT NULL PRIMARY KEY"

proc intGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                  isUnsigned:bool, isDefault:bool, default:int):string =
  result = &"\"{name}\" INTEGER"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

proc smallIntGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool, isDefault:bool, default:int):string =
  result = &"\"{name}\" SMALLINT"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

proc mediumIntGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                        isUnsigned:bool, isDefault:bool, default:int):string =
  result = &"\"{name}\" INTEGER"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

proc bigIntGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:int):string =
  result = &"\"{name}\" BIGINT"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(name:string, tableName:string, maximum:int, digit:int, nullable:bool,
                      isUnique:bool, isUnsigned:bool,
                      isDefault:bool, default:float):string =
  result = &"\"{name}\" NUMERIC({maximum}, {digit})"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

proc doubleGenerator*(name:string,tableName:string,  maximum:int, digit:int, nullable:bool,
                      isUnique:bool, isUnsigned:bool,
                      isDefault:bool, default:float):string =
  result = &"\"{name}\" NUMERIC({maximum}, {digit})"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

proc floatGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:float):string =
  result = &"\"{name}\" NUMERIC"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    result.add(&" CHECK (\"{name}\" > 0)")

# =============================================================================
# char
# =============================================================================
proc charGenerator*(name:string, tableName:string, maxLength:int, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"\"{name}\" CHAR({maxLength})"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    notAllowed("unsigned", "char")

proc stringGenerator*(name:string, tableName:string, maxLength:int, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"\"{name}\" VARCHAR({maxLength})"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    notAllowed("unsigned", "string")

proc textGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"\"{name}\" TEXT"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    notAllowed("unsigned", "text")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool,):string =
  result = &"\"{name}\" DATE"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if isUnsigned:
    notAllowed("unsigned", "date")

proc datetimeGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool,):string =
  result = &"\"{name}\" TIMESTAMP"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if isUnsigned:
    notAllowed("unsigned", "date")

proc timeGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool,):string =
  result = &"\"{name}\" TIME"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if isUnsigned:
    notAllowed("unsigned", "date")

proc timestampGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool,):string =
  result = &"\"{name}\" TIMESTAMP"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT (NOW())")

  if isUnsigned:
    notAllowed("unsigned", "date")

proc timestampsGenerator*():string =
  result = "\"created_at\" TIMESTAMP, "
  result.add("\"updated_at\" TIMESTAMP DEFAULT (NOW())")

proc softDeleteGenetator*():string =
  result = "\"deleted_at\" TIMESTAMP"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:string):string =
  result = &"\"{name}\" BYTEA"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    notAllowed("unsigned", "blob")

proc boolGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                    isUnsigned:bool, isDefault:bool, default:bool):string =
  result = &"\"{name}\" BOOLEAN"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT {default}")

  if isUnsigned:
    notAllowed("unsigned", "bool")

proc enumOptionsGenerator(name:string, options:varargs[JsonNode]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option.getStr}'"
    )

  return optionsString

proc enumGenerator*(name:string, tableName:string, options:varargs[JsonNode], nullable:bool,
                      isUnique:bool, isUnsigned:bool,
                      isDefault:bool, default:string):string =
  result = &"\"{name}\" CHARACTER"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    result.add(" UNIQUE")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default}'")

  if isUnsigned:
    notAllowed("unsigned", "text")

  let optionsString = enumOptionsGenerator(name, options)
  result.add(&" CHECK ({optionsString})")

proc jsonGenerator*(name:string, tableName:string, nullable:bool, isUnique:bool,
                      isUnsigned:bool, isDefault:bool, default:JsonNode):string =
  result = &"\"{name}\" JSON"

  if isUnique or not nullable or isDefault or isUnique:
    result.add(&" CONSTRAINT {tablename}_{name}")

  if isUnique:
    notAllowed("unique", "json")

  if not nullable:
    result.add(" NOT NULL")

  if isDefault:
    result.add(&" DEFAULT '{default.pretty}'")

  if isUnsigned:
    notAllowed("unsigned", "json")

proc foreignColumnGenerator*(name:string, isDefault:bool, default:int):string =
  result = &"\"{name}\" INT"
  if isDefault:
    result.add(&" DEFAULT {default}")

proc foreignGenerator*(table, column, refTable, refColumn:string,
                        foreignOnDelete:ForeignOnDelete):string =
  var onDeleteString = "RESTRICT"
  if foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  var refTable = refTable
  pgWrapUpper(refTable)
  return &", FOREIGN KEY(\"{column}\") REFERENCES {refTable}({refColumn}) ON DELETE {onDeleteString}"

proc alterAddForeignGenerator*(table, column, refTable, refColumn:string,
                            foreignOnDelete:ForeignOnDelete):string =
  var onDeleteString = "RESTRICT"
  if foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  var constraintName = &"{table}_{column}"
  pgWrapUpper(constraintName)
  var refTable = refTable
  pgWrapUpper(refTable)
  return &"CONSTRAINT {constraintName} FOREIGN KEY (\"{column}\") REFERENCES {refTable} ({refColumn}) ON DELETE {onDeleteString}"

proc alterDeleteGenerator*(table:string, column:string):string =
  var table = table
  pgWrapUpper(table)
  return &"ALTER TABLE {table} DROP {column}"

proc alterDeleteForeignGenerator*(table, column:string):string =
  var constraintName = &"{table}_{column}"
  pgWrapUpper(constraintName)
  var table = table
  pgWrapUpper(table)
  return &"ALTER TABLE {table} DROP CONSTRAINT {constraintName}"

proc indexGenerate*(table, column:string):string =
  var table = table
  pgWrapUpper(table)
  return &"CREATE INDEX {column}_index ON {table}({column})"
