import std/json
import std/strformat
import std/strutils
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../../query_util


# =============================================================================
# int
# =============================================================================
proc createSerialColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" SERIAL NOT NULL PRIMARY KEY"


proc createIntColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" INTEGER"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createSmallIntColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" SMALLINT"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createMediumIntColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" INTEGER"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createBigIntColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" BIGINT"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# float
# =============================================================================
proc createDecimalColumn(column:Column, table:Table):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  result = &"\"{column.name}\" NUMERIC({maximum}, {digit})"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createDoubleColumn(column:Column, table:Table):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  result = &"\"{column.name}\" NUMERIC({maximum}, {digit})"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createFloatColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" NUMERIC"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# char
# =============================================================================
proc createCharColumn(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" CHAR({maxLength})"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "char", column.name)


proc createStringColumn(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "string", column.name)


proc createTextColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TEXT"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "text", column.name)


# =============================================================================
# date
# =============================================================================
proc createDateColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" DATE"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc createDatetimeColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TIMESTAMP"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc createTimeColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TIME"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc createTimestampColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TIMESTAMP"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc createTimestampsColumn(column:Column, table:Table):string =
  result = "\"created_at\" TIMESTAMP, "
  result.add("\"updated_at\" TIMESTAMP DEFAULT (NOW())")


proc createSoftDeleteColumn(column:Column, table:Table):string =
  result = "\"deleted_at\" TIMESTAMP"


# =============================================================================
# others
# =============================================================================
proc createBlobColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" BYTEA"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "blob", column.name)


proc createBoolColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" BOOLEAN"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

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


proc createEnumColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" CHARACTER"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

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


proc createJsonColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" JSONB"

  if column.isUnique:
    result.add(&" CONSTRAINT {table.name}_{column.name}_unique UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowed("unsigned", "json", column.name)


proc createForeignColumnColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" INT"
  
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")


proc createStrForeignColumnColumn(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")


proc createForeignColumn(column:Column, table:Table):string =
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


proc indexColumn(column:Column, table:Table):string =
  let smallTable = table.name.toLowerAscii()
  return &"CREATE INDEX IF NOT EXISTS \"{smallTable}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"


proc createColumnString*(table:Table, column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.query = column.createSerialColumn(table)
  of rdbInteger:
    column.query = column.createIntColumn(table)
  of rdbSmallInteger:
    column.query = column.createIntColumn(table)
  of rdbMediumInteger:
    column.query = column.createIntColumn(table)
  of rdbBigInteger:
    column.query = column.createIntColumn(table)
    # float
  of rdbDecimal:
    column.query = column.createDecimalColumn(table)
  of rdbDouble:
    column.query = column.createDecimalColumn(table)
  of rdbFloat:
    column.query = column.createFloatColumn(table)
    # char
  of rdbUuid:
    column.query = column.createStringColumn(table)
  of rdbChar:
    column.query = column.createCharColumn(table)
  of rdbString:
    column.query = column.createStringColumn(table)
    # text
  of rdbText:
    column.query = column.createTextColumn(table)
  of rdbMediumText:
    column.query = column.createTextColumn(table)
  of rdbLongText:
    column.query = column.createTextColumn(table)
    # date
  of rdbDate:
    column.query = column.createDateColumn(table)
  of rdbDatetime:
    column.query = column.createDatetimeColumn(table)
  of rdbTime:
    column.query = column.createTimeColumn(table)
  of rdbTimestamp:
    column.query = column.createTimestampColumn(table)
  of rdbTimestamps:
    column.query = column.createTimestampsColumn(table)
  of rdbSoftDelete:
    column.query = column.createSoftDeleteColumn(table)
    # others
  of rdbBinary:
    column.query = column.createBlobColumn(table)
  of rdbBoolean:
    column.query = column.createBoolColumn(table)
  of rdbEnumField:
    column.query = column.createEnumColumn(table)
  of rdbJson:
    column.query = column.createJsonColumn(table)
  # foreign
  of rdbForeign:
    column.query = column.createForeignColumnColumn(table)
  of rdbStrForeign:
    column.query = column.createStrForeignColumnColumn(table)


proc createForeignString*(table:Table, column:Column) =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.foreignQuery = column.createForeignColumn(table)


proc createIndexString*(table:Table, column:Column) =
  if column.isIndex and column.typ != rdbIncrements:
    column.indexQuery = column.indexColumn(table)
