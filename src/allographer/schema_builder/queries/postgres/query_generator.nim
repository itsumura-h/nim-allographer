import std/json
import std/strformat
import std/strutils
import ../../enums
import ../../models/table
import ../../models/column
import ../query_util


# =============================================================================
# int
# =============================================================================
proc serialGenerator*(column:Column, table:Table):string =
  result = &"\"{column.name}\" SERIAL NOT NULL PRIMARY KEY"


proc intGenerator*(column:Column, table:Table):string =
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc smallIntGenerator*(column:Column, table:Table):string =
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc mediumIntGenerator*(column:Column, table:Table):string =
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc bigIntGenerator*(column:Column, table:Table):string =
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(column:Column, table:Table):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc doubleGenerator*(column:Column, table:Table):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc floatGenerator*(column:Column, table:Table):string =
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
    result.add(&" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# char
# =============================================================================
proc charGenerator*(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
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
    notAllowed("unsigned", "char", column.name)


proc stringGenerator*(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
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
    notAllowed("unsigned", "string", column.name)


proc textGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "text", column.name)


# =============================================================================
# date
# =============================================================================
proc dateGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "date", column.name)


proc datetimeGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "date", column.name)


proc timeGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "date", column.name)


proc timestampGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "date", column.name)


proc timestampsGenerator*(column:Column, table:Table):string =
  result = "\"created_at\" TIMESTAMP, "
  result.add("\"updated_at\" TIMESTAMP DEFAULT (NOW())")


proc softDeleteGenerator*(column:Column, table:Table):string =
  result = "\"deleted_at\" TIMESTAMP"


# =============================================================================
# others
# =============================================================================
proc blobGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "blob", column.name)


proc boolGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "bool", column.name)


proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option}'"
    )

  return optionsString


proc enumGenerator*(column:Column, table:Table):string =
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
    notAllowed("unsigned", "text", column.name)

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsGenerator(column.name, options)
  result.add(&" CHECK ({optionsString})")


proc jsonGenerator*(column:Column, table:Table):string =
  result = &"\"{column.name}\" JSONB"

  if column.isUnique or not column.isNullable or column.isDefault:
    result.add(&" CONSTRAINT {table.name}_{column.name}")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowed("unsigned", "json", column.name)


proc foreignColumnGenerator*(column:Column, table:Table):string =
  result = &"\"{column.name}\" INT"
  
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")


proc strForeignColumnGenerator*(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")


proc foreignGenerator*(column:Column, table:Table):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let refColumn = column.info["column"].getStr
  let refTable = column.info["table"].getStr
  return &"FOREIGN KEY(\"{column.name}\") REFERENCES \"{refTable}\"(\"{refColumn}\") ON DELETE {onDeleteString}"


proc alterAddForeignGenerator*(column:Column, table:Table):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let constraintName = &"{table.name}_{column.name}"
  let refColumn = column.info["column"].getStr
  let refTable = column.info["table"].getStr
  return &"CONSTRAINT \"{constraintName}\" FOREIGN KEY (\"{column.name}\") REFERENCES \"{refTable}\" (\"{refColumn}\") ON DELETE {onDeleteString}"


proc alterDeleteGenerator*(column:Column, table:Table):string =
  return &"ALTER TABLE \"{table.name}\" DROP '{column.name}'"


proc alterDeleteForeignGenerator*(column:Column, table:Table):string =
  let constraintName = &"{table.name}_{column.name}"
  return &"ALTER TABLE \"{table.name}\" DROP CONSTRAINT {constraintName}"


proc indexGenerator*(column:Column, table:Table):string =
  let smallTable = table.name.toLowerAscii()
  return &"CREATE INDEX IF NOT EXISTS \"{smallTable}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"
