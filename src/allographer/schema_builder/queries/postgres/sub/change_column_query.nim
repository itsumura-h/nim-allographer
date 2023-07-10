import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../../query_util


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
# proc changeSerialColumn(column:Column, table:Table):seq[string] =
#   result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" TYPE INTEGER")
#   result.add(&"ALTER TABLE \"{table.name}\" ADD PRIMARY KEY (\"{column.name}\")")
#   result.add(&"ALTER TABLE \"{table.name}\" ALTER COLUMN \"{column.name}\" SET NOT NULL")
#   result.add(&"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{column.name}\" CHECK(\"{column.name}\" >= 0)")


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


proc changeForeignKey(column:Column, table:Table):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let refColumn = column.info["column"].getStr
  let refTable = column.info["table"].getStr
  return &"ALTER TABLE \"{table.name}\" ADD CONSTRAINT \"{table.name}_{column.name}_fkey\" FOREIGN KEY(\"{column.name}\") REFERENCES \"{refTable}\"(\"{refColumn}\") ON DELETE {onDeleteString}"


proc changeForeignColumn(column:Column, table:Table):seq[string] =
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

  result.add(changeForeignKey(column, table))


proc changeStrForeignColumn(column:Column, table:Table):seq[string] =
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

  result.add(changeForeignKey(column, table))


proc indexColumn(column:Column, table:Table):string =
  return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"


proc changeColumnString*(table:Table, column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    notAllowedTypeInChange("increments")
  of rdbInteger:
    column.queries = column.changeIntColumn(table)
  of rdbSmallInteger:
    column.queries = column.changeSmallIntColumn(table)
  of rdbMediumInteger:
    column.queries = column.changeMediumIntColumn(table)
  of rdbBigInteger:
    column.queries = column.changeBigIntColumn(table)
    # float
  of rdbDecimal:
    column.queries = column.changeDecimalColumn(table)
  of rdbDouble:
    column.queries = column.changeDecimalColumn(table)
  of rdbFloat:
    column.queries = column.changeFloatColumn(table)
    # char
  of rdbUuid:
    column.queries = column.changeStringColumn(table)
  of rdbChar:
    column.queries = column.changeCharColumn(table)
  of rdbString:
    column.queries = column.changeStringColumn(table)
    # text
  of rdbText:
    column.queries = column.changeTextColumn(table)
  of rdbMediumText:
    column.queries = column.changeTextColumn(table)
  of rdbLongText:
    column.queries = column.changeTextColumn(table)
    # date
  of rdbDate:
    column.queries = column.changeDateColumn(table)
  of rdbDatetime:
    column.queries = column.changeDatetimeColumn(table)
  of rdbTime:
    column.queries = column.changeTimeColumn(table)
  of rdbTimestamp:
    column.queries = column.changeTimestampColumn(table)
  of rdbTimestamps:
    notAllowedTypeInChange("timestamps")
  of rdbSoftDelete:
    notAllowedTypeInChange("softDelete")
    # others
  of rdbBinary:
    column.queries = column.changeBlobColumn(table)
  of rdbBoolean:
    column.queries = column.changeBoolColumn(table)
  of rdbEnumField:
    column.queries = column.changeEnumColumn(table)
  of rdbJson:
    column.queries = column.changeJsonColumn(table)
  # foreign
  of rdbForeign:
    notAllowedTypeInChange("foreign")
    # column.queries = column.changeForeignColumn(table)
  of rdbStrForeign:
    notAllowedTypeInChange("strForeign")
    # column.queries = column.changeStrForeignColumn(table)


proc changeIndexString*(table:Table, column:Column) =
  if column.isIndex and column.typ != rdbIncrements:
    column.queries.add(column.indexColumn(table))
