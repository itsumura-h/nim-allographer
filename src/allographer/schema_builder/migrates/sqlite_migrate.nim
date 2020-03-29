import strformat, strutils, json
import
  ../table,
  ../column
import ../generators/sqlite_generators


proc migrate*(this:Table):string =
  var columnString = ""
  var foreignString = ""
  for i, column in this.columns:
    if i > 0: columnString.add(", ")

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
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
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
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
          )
        )
      of rdbFloat:
        columnString.add(
          floatGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
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
            column.isDefault,
            column.defaultString,
            column.isUnsigned
          )
        )
      of rdbString:
        columnString.add(
          varcharGenerator(
            column.name,
            parseInt($column.info["maxLength"]),
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultString,
            column.isUnsigned
          )
        )
      # text ==================================================================
      of rdbText:
        columnString.add(
          textGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultString,
            column.isUnsigned
          )
        )
      of rdbMediumText:
        columnString.add(
          textGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultString,
            column.isUnsigned
          )
        )
      of rdbLongText:
        columnString.add(
          textGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultString,
            column.isUnsigned
          )
        )
      # date ==================================================================
      of rdbDate:
        columnString.add(
          dateGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.isUnsigned
          )
        )
      of rdbDatetime:
        columnString.add(
          datetimeGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.isUnsigned
          )
        )
      of rdbTime:
        columnString.add(
          timeGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.isUnsigned
          )
        )
      of rdbTimestamp:
        columnString.add(
          timestampGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.isUnsigned
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
            column.isUnsigned
          )
        )
      of rdbBoolean:
        columnString.add(
          boolGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultBool,
            column.isUnsigned
          )
        )
      of rdbEnumField:
        columnString.add(
          enumGenerator(
            column.name,
            column.info["options"].getElems,
            column.isNullable,
            column.isUnique,
            column.isDefault,
            column.defaultString,
            column.isUnsigned
          )
        )
      of rdbJson:
        columnString.add(
          jsonGenerator(
            column.name,
            column.isNullable,
            column.isUnique,
            column.isUnsigned
          )
        )
      of rdbForeign:
        columnString.add(
          foreignColumnGenerator(column.name)
        )
        foreignString.add(
          foreignGenerator(
            column.name,
            column.info["table"].getStr(),
            column.info["column"].getStr(),
            column.foreignOnDelete
          )
        )


  var query = &"CREATE TABLE \"{this.name}\" ({columnString}{foreignString})"
  return query
