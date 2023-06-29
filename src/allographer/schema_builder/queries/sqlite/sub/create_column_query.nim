## https://www.sqlite.org/lang_createtable.html#constraints

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
proc createSerialColumn(column:Column):string =
  result = &"'{column.name}' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"


proc createIntColumn(column:Column):string =
  result = &"'{column.name}' INTEGER"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} >= 0)")


# =============================================================================
# float
# =============================================================================
proc createDecimalColumn(column:Column):string =
  result = &"'{column.name}' NUMERIC"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} >= 0)")


proc createFloatColumn(column:Column):string =
  result = &"'{column.name}' REAL"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK ({column.name} >= 0)")


# =============================================================================
# char
# =============================================================================
proc createUuidColumn(column:Column):string =
  result = &"'{column.name}' VARCHAR"

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  result.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowed("unsigned", "varchar", column.name)


proc createCharColumn(column:Column):string =
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
    notAllowed("unsigned", "char", column.name)


proc createVarcharColumn(column:Column):string =
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
    notAllowed("unsigned", "varchar", column.name)


proc createTextColumn(column:Column):string =
  result = &"'{column.name}' TEXT"

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
proc createDateColumn(column:Column):string =
  result = &"'{column.name}' DATE"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)


proc createDatetimeColumn(column:Column):string =
  result = &"'{column.name}' DATETIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "datetime", column.name)


proc createTimeColumn(column:Column):string =
  result = &"'{column.name}' TIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "time", column.name)


proc createTimestampColumn(column:Column):string =
  result = &"'{column.name}' DATETIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "timestamp", column.name)


proc createTimestampsColumn(column:Column):string =
  result = "'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP, "
  result.add("'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP")


proc createSoftDeleteColumn(column:Column):string =
  result = "'deleted_at' DATETIME"


# =============================================================================
# others
# =============================================================================
proc createBlobColumn(column:Column):string =
  result = &"'{column.name}' BLOB"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "blob", column.name)


proc createBoolColumn(column:Column):string =
  result = &"'{column.name}' TINYINT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowed("unsigned", "bool", column.name)


proc enumOptionsColumn(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option}'"
    )

  return optionsString


proc createEnumColumn(column:Column):string =
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

  let optionsString = enumOptionsColumn(column.name, options)
  result.add(&" CHECK ({optionsString})")

  if column.isUnsigned:
    notAllowed("unsigned", "enum", column.name)


proc createJsonColumn(column:Column):string =
  result = &"'{column.name}' TEXT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowed("unsigned", "json", column.name)


# =============================================================================
# foreign key
# =============================================================================
proc createForeignColumn(column:Column):string =
  result = &"'{column.name}' INTEGER"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")


proc createStrForeignColumn(column:Column):string =
  result = &"'{column.name}' VARCHAR"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")


proc createForeignKey(column:Column):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let tableName = column.info["table"].getStr
  let columnnName = column.info["column"].getStr
  return &"FOREIGN KEY('{column.name}') REFERENCES \"{tableName}\"('{columnnName}') ON DELETE {onDeleteString}"


proc createIndexColumn(column:Column, table:Table):string =
  let table = table.name
  let smallTable = table.toLowerAscii()
  return &"CREATE INDEX IF NOT EXISTS \"{smallTable}_{column.name}_index\" ON \"{table}\"('{column.name}')"


proc createColumnString*(column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.query = column.createSerialColumn()
  of rdbInteger:
    column.query = column.createIntColumn()
  of rdbSmallInteger:
    column.query = column.createIntColumn()
  of rdbMediumInteger:
    column.query = column.createIntColumn()
  of rdbBigInteger:
    column.query = column.createIntColumn()
    # float
  of rdbDecimal:
    column.query = column.createDecimalColumn()
  of rdbDouble:
    column.query = column.createDecimalColumn()
  of rdbFloat:
    column.query = column.createFloatColumn()
    # char
  of rdbUuid:
    column.query = column.createUuidColumn()
  of rdbChar:
    column.query = column.createCharColumn()
  of rdbString:
    column.query = column.createVarcharColumn()
    # text
  of rdbText:
    column.query = column.createTextColumn()
  of rdbMediumText:
    column.query = column.createTextColumn()
  of rdbLongText:
    column.query = column.createTextColumn()
    # date
  of rdbDate:
    column.query = column.createDateColumn()
  of rdbDatetime:
    column.query = column.createDatetimeColumn()
  of rdbTime:
    column.query = column.createTimeColumn()
  of rdbTimestamp:
    column.query = column.createTimestampColumn()
  of rdbTimestamps:
    column.query = column.createTimestampsColumn()
  of rdbSoftDelete:
    column.query = column.createSoftDeleteColumn()
    # others
  of rdbBinary:
    column.query = column.createBlobColumn()
  of rdbBoolean:
    column.query = column.createBoolColumn()
  of rdbEnumField:
    column.query = column.createEnumColumn()
  of rdbJson:
    column.query = column.createJsonColumn()
  # foreign
  of rdbForeign:
    column.query = column.createForeignColumn()
  of rdbStrForeign:
    column.query = column.createStrForeignColumn()


proc createForeignString*(column:Column) =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.foreignQuery = column.createForeignKey()


proc createIndexString*(table:Table, column:Column) =
  if not column.isUnique and column.isIndex:
      column.indexQuery = column.createIndexColumn(table)
