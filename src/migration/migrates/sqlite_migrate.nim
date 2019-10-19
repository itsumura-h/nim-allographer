import db_common, db_sqlite, strformat, strutils, json
import ../../modules/database
import ../base
import ../generators/sqlite_generators

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
            column.isUnsigned
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
            column.defaultFloat
          )
        )
      of dbFloat:
        columnString.add(
          floatGenerator(
            column.name,
            column.isNullable,
            column.isDefault,
            column.defaultFloat
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
            column.isNullable,
            column.isDefault,
            column.defaultString
          )
        )
      # date ==================================================================
      of dbDate:
        columnString.add(
          dateGenerator(column.name, column.isNullable)
        )
      of dbDatetime:
        columnString.add(
          datetimeGenerator(column.name, column.isNullable)
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
      else:
        echo ""

  # primary key
  var primaryString = ""
  if primaryColumn.len > 0:
    primaryString.add(
      &", PRIMARY KEY ({primaryColumn})"
    )

  var query = &"CREATE TABLE {this.name} ({columnString})"

  echo query
  let db = db()
  try:
    db.exec(sql"drop table table_name")
  except Exception:
    echo getCurrentExceptionMsg()

  db.exec(sql query)
  db.close()