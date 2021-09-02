import strformat, strutils, json
import
  ../table,
  ../column
import ../generators/sqlite_generators

proc generateColumnString*(column:Column):string =
  var columnString = ""
  case column.typ:
  # int ===================================================================
  of rdbIncrements:
    columnString.add(
      serialGenerator(column.name)
    )
  of rdbInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbSmallInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbMediumInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbBigInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  # float =================================================================
  of rdbDecimal:
    columnString.add(
      decimalGenerator(
        column.name,
        parseInt($column.info["maximum"]),
        parseInt($column.info["digit"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  of rdbDouble:
    columnString.add(
      decimalGenerator(
        column.name,
        parseInt($column.info["maximum"]),
        parseInt($column.info["digit"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  of rdbFloat:
    columnString.add(
      floatGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  # char ==================================================================
  of rdbChar:
    columnString.add(
      charGenerator(
        column.name,
        parseInt($column.info["maxLength"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbString:
    columnString.add(
      varcharGenerator(
        column.name,
        parseInt($column.info["maxLength"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  # text ==================================================================
  of rdbText:
    columnString.add(
      textGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbMediumText:
    columnString.add(
      textGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbLongText:
    columnString.add(
      textGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  # date ==================================================================
  of rdbDate:
    columnString.add(
      dateGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbDatetime:
    columnString.add(
      datetimeGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTime:
    columnString.add(
      timeGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTimestamp:
    columnString.add(
      timestampGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTimestamps:
    columnString.add(
      timestampsGenerator()
    )
  of rdbSoftDelete:
    columnString.add(
      softDeleteGenerator()
    )
  # others ================================================================
  of rdbBinary:
    columnString.add(
      blobGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbBoolean:
    columnString.add(
      boolGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultBool,
      )
    )
  of rdbEnumField:
    columnString.add(
      enumGenerator(
        column.name,
        column.info["options"].getElems,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbJson:
    columnString.add(
      jsonGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultJson,
      )
    )
  of rdbForeign:
    columnString.add(
      foreignColumnGenerator(column.name, column.isDefault, column.defaultInt)
    )
  return columnString

proc generateForeignString(column:Column):string =
  if column.typ == rdbForeign:
    return foreignGenerator(
      column.name,
      column.info["table"].getStr(),
      column.info["column"].getStr(),
      column.foreignOnDelete
    )

proc generateAlterForeignString(column:Column):string =
  if column.typ == rdbForeign:
    return alterAddForeignGenerator(
      column.info["table"].getStr(),
      column.info["column"].getStr(),
    )

proc migrate*(this:Table):string =
  var columnString = ""
  var foreignString = ""
  for i, column in this.columns:
    if i > 0: columnString.add(", ")
    columnString.add(
      generateColumnString(column)
    )
    if column.typ == rdbForeign:
      if foreignString.len > 0: foreignString.add(", ")
      foreignString.add(
        generateForeignString(column)
      )

  return &"CREATE TABLE \"{this.name}\" ({columnString}{foreignString})"

proc migrateAlter*(column:Column, table:string):string =
  let columnString = generateColumnString(column)
  let foreignString = generateAlterForeignString(column)

  if foreignString.len > 0:
    return &"ALTER TABLE \"{table}\" ADD COLUMN {columnString} {foreignString}"
  else:
    return &"ALTER TABLE \"{table}\" ADD COLUMN {columnString}"


proc createIndex*(table, column:string):string =
  return indexGenerate(table, column)
