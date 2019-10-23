import db_common, strformat, strutils, json
import ../base
import ../generators/mysql_generators


proc migrate*(this:Model):string =

  var columnString = ""
  var primaryColumn = ""
  for i, column in this.columns:
    echo repr column
    if i > 0:
      columnString.add(", ")

    case column.typ:
      # int ===================================================================
      of dbSerial:
        primaryColumn = column.name
        columnString.add(
          serialGenerator(column.name)
        )
      of dbInt:
        columnString.add(
          intGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultInt,
            column.isUnsigned,
            column.info["size"].getStr()
          )
        )
      # float =================================================================
      of dbDecimal:
        columnString.add(
          decimalGenerator(
            column.name,
            parseInt($column.info["maximum"]),
            parseInt($column.info["digit"]),
            column.isNullable,
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
          )
        )
      of dbFloat:
        var
          isWithOption = false
          maximum = 0
          digit = 0

        if column.info != nil:
          isWithOption = true
          maximum = parseInt($column.info["maximum"])
          digit = parseInt($column.info["digit"])

        columnString.add(
          floatGenerator(
            column.name,
            isWithOption,
            maximum,
            digit,
            column.isNullable,
            column.isDefault,
            column.defaultFloat,
            column.isUnsigned
          )
        )
      # char ==================================================================
      of dbFixedChar:
        columnString.add(
          charGenerator(
            column.name,
            parseInt($column.info["maxLength"]),
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of dbVarchar:
        columnString.add(
          varcharGenerator(
            column.name,
            parseInt($column.info["maxLength"]),
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of dbXml:
        columnString.add(
          textGenerator(
            column.name,
            column.info["size"].getStr(),
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      # date ==================================================================
      of dbDate:
        columnString.add(
          dateGenerator(column.name, column.isNullable, column.isDefault)
        )
      of dbDatetime:
        columnString.add(
          datetimeGenerator(column.name, column.isNullable, column.isDefault)
        )
      of dbTime:
        columnString.add(
          timeGenerator(
            column.name,
            column.isNullable,
            column.isDefault
          )
        )
      of dbTimestamp:
        columnString.add(
          timestampGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.info["status"].getStr
          )
        )
      # others ================================================================
      of dbBlob:
        columnString.add(
          blobGenerator(column.name, column.isNullable)
        )
      of dbBool:
        columnString.add(
          boolGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultBool
          )
        )
      of dbEnum:
        columnString.add(
          enumGenerator(
            column.name,
            column.info["options"].getElems,
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      of dbJson:
        columnString.add(
          jsonGenerator(
            column.name,
            column.isNullable
          )
        )
      else:
        echo ""

  # primary key
  var primaryString = ""
  if primaryColumn.len > 0:
    primaryString.add(
      &", PRIMARY KEY ({primaryColumn})"
    )

  var query = &"CREATE TABLE {this.name} ({columnString})"
  return query
