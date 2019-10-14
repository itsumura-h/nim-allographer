import db_common, strformat, strutils, json
import util, generators
include ../modules/database

type 
  Model* = ref object
    name*: string
    columns*: seq[Column]

  Column* = ref object
    name*: string
    typ*: DbTypeKind
    nullable*: bool
    default*: string
    info*: JsonNode

export Column

proc new*(this:Model, name:string, columns:varargs[Column]): Model =
  Model(
    name: name,
    columns: @columns
  )

proc driverTypeError() =
  let driver = util.getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")

proc migrate*(this:Model) =
  driverTypeError()
  var columnString = ""
  var i = 0
  var primaryColumn = ""
  for column in this.columns:
    echo repr column
    if i > 0:
      columnString.add(", ")
    i += 1

    if column.typ == dbSerial:
      primaryColumn = column.name
      columnString.add(
        serialGenerator(column.name)
      )
    elif column.typ == dbInt:
      columnString.add(
        intGenerator(column.name, column.nullable, column.default)
      )
    elif column.typ == dbBlob:
      columnString.add(
        blobGenerator(column.name, column.nullable)
      )
    elif column.typ == dbBool:
      columnString.add(
        boolGenerator(column.name, column.nullable, column.default)
      )
    elif column.typ == dbFixedChar:
      let name = column.name
      let maxLength = parseInt($column.info["maxLength"])
      let nullable = column.nullable
      let default = column.default
      columnString.add(
        charGenerator(name, maxLength, nullable, default)
      )
    # elif column.typ.kind == dbDate:
    #   columnString.add(
    #     dateGenerator(column.name, column.typ.notNull)
    #   )
    # elif column.typ.kind == dbDatetime:
    #   columnString.add(
    #     datetimeGenerator(column.name, column.typ.notNull)
    #   )

  # primary key
  var primaryString = ""
  if primaryColumn.len > 0:
    primaryString.add(
      &", PRIMARY KEY ({primaryColumn})"
    )

  let driver = util.getDriver()
  var query = ""

  # create table
  if driver == "sqlite":
    query.add(
      &"CREATE TABLE {this.name} ({columnString})"
    )
  elif driver == "mysql":
    query.add(
      ""
    )
  elif driver == "postgres":
    query.add(
      ""
    )

  var charset = getCharset()
  query.add(
    &"{charset}"
  )
  echo query
  let db = db()
  try:
    db.exec(sql"drop table test")
  except Exception:
    echo getCurrentExceptionMsg()

  db.exec(sql query)
  db.close()
