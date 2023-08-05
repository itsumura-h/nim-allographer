import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../../schema_utils


proc commonSetup(column:Column, table:Table):seq[string] =
  ## drop default, drop unique, drop enum, drop fkey, drop index
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" DROP DEFAULT")
  result.add(&"ALTER TABLE \"{table.name}\" DROP CONSTRAINT IF EXISTS \"{table.name}_{column.name}_unique\"")
  result.add(&"ALTER TABLE \"{table.name}\" DROP CONSTRAINT IF EXISTS \"{table.name}_{column.name}_enum\"")
  result.add(&"ALTER TABLE \"{table.name}\" DROP CONSTRAINT IF EXISTS \"{table.name}_{column.name}_fkey\"")
  result.add(&"DROP INDEX IF EXISTS \"{table.name}_{column.name}_index\"")


# =============================================================================
# int
# =============================================================================
proc changeIntColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE INTEGER")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK (\"{column.name}\" >= 0)")


proc changeSmallIntColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE SMALLINT")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK (\"{column.name}\" >= 0)")


proc changeMediumIntColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE INTEGER")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK (\"{column.name}\" >= 0)")


proc changeBigIntColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BIGINT")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultInt}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# float
# =============================================================================
proc changeDecimalColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE NUMERIC({maximum}, {digit})")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultFloat}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK (\"{column.name}\" >= 0)")


proc changeFloatColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE NUMERIC")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultFloat}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# char
# =============================================================================
proc changeCharColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)

  let maxLength = column.info["maxLength"].getInt
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE CHAR({maxLength})")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "char", column.name)


proc changeStringColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)

  let maxLength = column.info["maxLength"].getInt
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE VARCHAR({maxLength})")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "string", column.name)


proc changeTextColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TEXT")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)


# =============================================================================
# date
# =============================================================================
proc changeDateColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE DATE")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)


proc changeDatetimeColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TIMESTAMP")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "datetime", column.name)


proc changeTimeColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TIME")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "time", column.name)


proc changeTimestampColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE TIMESTAMP")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT (NOW())")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "time", column.name)


# =============================================================================
# others
# =============================================================================
proc changeBlobColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BYTEA")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)


proc changeBoolColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE BOOLEAN")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT {column.defaultBool}")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)


proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option}'"
    )

  return optionsString


proc changeEnumColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)  
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE CHARACTER")

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)
  let optionsString = enumOptionsGenerator(column.name, options)
  result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_enum\" CHECK ({optionsString})")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultString}'")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)


proc changeJsonColumn(column:Column, table:Table):seq[string] =
  result = commonSetup(column, table)
  result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE JSONB")

  if column.isDefault:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnique:
    result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE (\"{column.name}\")")

  if not column.isNullable:
    result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)


proc indexColumn(column:Column, table:Table):string =
  return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"


proc changeColumnString*(table:Table, column:Column):seq[string] =
  case column.typ:
    # int
  of rdbIncrements:
    notAllowedType("increments")
  of rdbInteger:
    return column.changeIntColumn(table)
  of rdbSmallInteger:
    return column.changeSmallIntColumn(table)
  of rdbMediumInteger:
    return column.changeMediumIntColumn(table)
  of rdbBigInteger:
    return column.changeBigIntColumn(table)
    # float
  of rdbDecimal:
    return column.changeDecimalColumn(table)
  of rdbDouble:
    return column.changeDecimalColumn(table)
  of rdbFloat:
    return column.changeFloatColumn(table)
    # char
  of rdbUuid:
    return column.changeStringColumn(table)
  of rdbChar:
    return column.changeCharColumn(table)
  of rdbString:
    return column.changeStringColumn(table)
    # text
  of rdbText:
    return column.changeTextColumn(table)
  of rdbMediumText:
    return column.changeTextColumn(table)
  of rdbLongText:
    return column.changeTextColumn(table)
    # date
  of rdbDate:
    return column.changeDateColumn(table)
  of rdbDatetime:
    return column.changeDatetimeColumn(table)
  of rdbTime:
    return column.changeTimeColumn(table)
  of rdbTimestamp:
    return column.changeTimestampColumn(table)
  of rdbTimestamps:
    notAllowedType("timestamps")
  of rdbSoftDelete:
    notAllowedType("softDelete")
    # others
  of rdbBinary:
    return column.changeBlobColumn(table)
  of rdbBoolean:
    return column.changeBoolColumn(table)
  of rdbEnumField:
    return column.changeEnumColumn(table)
  of rdbJson:
    return column.changeJsonColumn(table)
  # foreign
  of rdbForeign:
    notAllowedType("foreign")
  of rdbStrForeign:
    notAllowedType("strForeign")


proc changeIndexString*(table:Table, column:Column):string =
  return column.indexColumn(table)
