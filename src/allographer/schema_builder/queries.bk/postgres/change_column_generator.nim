## https://www.postgresql.org/docs/current/sql-altertable.html

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
proc serialChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BIGINT")
  result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
  result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")


proc intChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE INTEGER")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK (\"{column.name}\" >= 0)")


proc smallIntChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE SMALLINT")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK (\"{column.name}\" >= 0)")


proc mediumIntChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE INTEGER")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK (\"{column.name}\" >= 0)")


proc bigIntChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BIGINT")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# float
# =============================================================================
proc decimalChangeGenerator*(column:Column, table:Table):seq[string] =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE NUMERIC({maximum}, {digit})")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultFloat}")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK (\"{column.name}\" >= 0)")


proc floatChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE NUMERIC")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultFloat}")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# char
# =============================================================================
proc charChangeGenerator*(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE CHAR({maxLength})")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "char", column.name)


proc stringChangeGenerator*(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE VARCHAR({maxLength})")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "string", column.name)


proc textChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TEXT")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "text", column.name)


# =============================================================================
# date
# =============================================================================
proc dateChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE DATE")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc datetimeChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TIMESTAMP")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "datetime", column.name)


proc timeChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TIME")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc timestampChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TIMESTAMP")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "time", column.name)


proc timestampsChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"created_at\" TYPE TIMESTAMP")
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"updated_at\" TYPE TIMESTAMP DEFAULT (NOW())")


proc softDeleteChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"deleted_at\" TYPE TIMESTAMP")


# =============================================================================
# others
# =============================================================================
proc blobChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BYTEA")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "blob", column.name)


proc boolChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BOOLEAN")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultBool}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "bool", column.name)


proc enumOptionsChangeGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option}'"
    )

  return optionsString


proc enumChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE CHARACTER")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "enum", column.name)

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsChangeGenerator(column.name, options)
  result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT {table.name}_{column.name} CHECK ({optionsString})")


proc jsonChangeGenerator*(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE JSONB")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnique:
    result.add(&"CREATE UNIQUE INDEX IF NOT EXISTS {table.name}_{column.name}_unique ON \"{table.name}\"(\"{column.name}\")")
    result.add(&"ALTER TABLE \"{table.name}\" ADD UNIQUE USING INDEX {table.name}_{column.name}_unique")

  if column.isUnsigned:
    notAllowed("unsigned", "json", column.name)


# proc foreignColumnChangeGenerator*(column:Column, table:Table):seq[string] =
#   if isAlter:
#     result = &"\"{column.name}\" TYPE INT"
#   else:
#     result = &"\"{column.name}\" INT"
  
#   if column.isDefault:
#     result.add(&" DEFAULT {column.defaultInt}")


# proc strForeignColumnChangeGenerator*(column:Column, table:Table):seq[string] =
#   let maxLength = column.info["maxLength"].getInt
#   if isAlter:
#     result = &"\"{column.name}\" TYPE VARCHAR({maxLength})"
#   else:
#     result = &"\"{column.name}\" VARCHAR({maxLength})"

#   if column.isDefault:
#     result.add(&" DEFAULT {column.defaultString}")


# proc foreignChangeGenerator*(column:Column, table:Table):seq[string] =
#   var onDeleteString = "RESTRICT"
#   if column.foreignOnDelete == CASCADE:
#     onDeleteString = "CASCADE"
#   elif column.foreignOnDelete == SET_NULL:
#     onDeleteString = "SET NULL"
#   elif column.foreignOnDelete == NO_ACTION:
#     onDeleteString = "NO ACTION"

#   let refColumn = column.info["column"].getStr
#   let refTable = column.info["table"].getStr
#   return &"FOREIGN KEY(\"{column.name}\") REFERENCES \"{refTable}\"(\"{refColumn}\") ON DELETE {onDeleteString}"


# proc alterAddForeignChangeGenerator*(column:Column, table:Table):seq[string] =
#   var onDeleteString = "RESTRICT"
#   if column.foreignOnDelete == CASCADE:
#     onDeleteString = "CASCADE"
#   elif column.foreignOnDelete == SET_NULL:
#     onDeleteString = "SET NULL"
#   elif column.foreignOnDelete == NO_ACTION:
#     onDeleteString = "NO ACTION"

#   let constraintName = &"{table.name}_{column.name}"
#   let refColumn = column.info["column"].getStr
#   let refTable = column.info["table"].getStr
#   return &"CONSTRAINT \"{constraintName}\" FOREIGN KEY (\"{column.name}\") REFERENCES \"{refTable}\" (\"{refColumn}\") ON DELETE {onDeleteString}"


# proc alterDeleteChangeGenerator*(column:Column, table:Table):seq[string] =
#   return &"ALTER TABLE \"{table.name}\" DROP '{column.name}'"


# proc alterDeleteForeignChangeGenerator*(column:Column, table:Table):seq[string] =
#   let constraintName = &"{table.name}_{column.name}"
#   return &"ALTER TABLE \"{table.name}\" DROP CONSTRAINT {constraintName}"


# proc indexChangeGenerator*(column:Column, table:Table):seq[string] =
#   let smallTable = table.name.toLowerAscii()
#   return &"CREATE INDEX IF NOT EXISTS \"{smallTable}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"
