import db_common, strformat
import columnGenerator

type  Model* = ref object of RootObj
  name*: string
  columns*: seq[DbColumn]

proc new*(this:Model, name:string, columns:varargs[DbColumn]): Model =
  Model(
    name: name,
    columns: @columns
  )

proc driverTypeError() =
  let driver = getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid driver type")

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

    if column.typ.kind == dbSerial:
      primaryColumn = column.name
      columnString.add(
        serialGenerator(column.name)
      )
    elif column.typ.kind == dbInt:
      columnString.add(
        intGenerator(column.name, column.typ.notNull)
      )

  # create table
  var charset = getCharset()
  var query =  &"CREATE TABLE {this.name} ({columnString}, PRIMARY KEY ({primaryColumn})) {charset}"
  echo query