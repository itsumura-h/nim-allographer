## https://www.sqlite.org/lang_createtable.html#constraints

import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../schema_utils


# =============================================================================
# int
# =============================================================================
proc createSerialColumn(column:Column):string =
  result = &"'{column.name}' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT"


proc createIntColumn(column:Column):string =
  result = &"'{column.name}' INTEGER"

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "integer", column.name)

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
  result = &"'{column.name}' VARCHAR UNIQUE"

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  result.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


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
    notAllowedOption("unsigned", "char", column.name)


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
    notAllowedOption("unsigned", "varchar", column.name)


proc createTextColumn(column:Column):string =
  result = &"'{column.name}' TEXT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)


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
    notAllowedOption("unsigned", "date", column.name)


proc createDatetimeColumn(column:Column):string =
  result = &"'{column.name}' DATETIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "datetime", column.name)


proc createTimeColumn(column:Column):string =
  result = &"'{column.name}' TIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "time", column.name)


proc createTimestampColumn(column:Column):string =
  result = &"'{column.name}' DATETIME"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "timestamp", column.name)


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
    notAllowedOption("unsigned", "blob", column.name)


proc createBoolColumn(column:Column):string =
  result = &"'{column.name}' TINYINT"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)


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
    notAllowedOption("unsigned", "enum", column.name)


proc createJsonColumn(column:Column):string =
  result = &"'{column.name}' JSON"

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)


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
  return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"('{column.name}')"


proc createColumnString*(column:Column):string =
  case column.typ:
    # int
  of rdbIncrements:
    return column.createSerialColumn()
  of rdbInteger:
    return column.createIntColumn()
  of rdbSmallInteger:
    return column.createIntColumn()
  of rdbMediumInteger:
    return column.createIntColumn()
  of rdbBigInteger:
    return column.createIntColumn()
    # float
  of rdbDecimal:
    return column.createDecimalColumn()
  of rdbDouble:
    return column.createDecimalColumn()
  of rdbFloat:
    return column.createFloatColumn()
    # char
  of rdbUuid:
    return column.createUuidColumn()
  of rdbChar:
    return column.createCharColumn()
  of rdbString:
    return column.createVarcharColumn()
    # text
  of rdbText:
    return column.createTextColumn()
  of rdbMediumText:
    return column.createTextColumn()
  of rdbLongText:
    return column.createTextColumn()
    # date
  of rdbDate:
    return column.createDateColumn()
  of rdbDatetime:
    return column.createDatetimeColumn()
  of rdbTime:
    return column.createTimeColumn()
  of rdbTimestamp:
    return column.createTimestampColumn()
  of rdbTimestamps:
    return column.createTimestampsColumn()
  of rdbSoftDelete:
    return column.createSoftDeleteColumn()
    # others
  of rdbBinary:
    return column.createBlobColumn()
  of rdbBoolean:
    return column.createBoolColumn()
  of rdbEnumField:
    return column.createEnumColumn()
  of rdbJson:
    return column.createJsonColumn()
  # foreign
  of rdbForeign:
    return column.createForeignColumn()
  of rdbStrForeign:
    return column.createStrForeignColumn()


proc createForeignString*(column:Column):string =
  # if column.typ == rdbForeign or column.typ == rdbStrForeign:
  return column.createForeignKey()


proc createIndexString*(table:Table, column:Column):string =
  # if column.isIndex:
  return column.createIndexColumn(table)
