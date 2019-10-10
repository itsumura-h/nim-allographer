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

    if column.typ.kind == dbSerial:
      primaryColumn = column.name
      columnString.add(
        serialGenerator(column.name)
      )
    elif column.typ.kind == dbInt:
      columnString.add(
        intGenerator(column.name, column.typ.notNull)
      )
    elif column.typ.kind == dbBool:
      columnString.add(
        boolGenerator(column.name, column.typ.notNull)
      )
    elif column.typ.kind == dbBlob:
      columnString.add(
        blobGenerator(column.name, column.typ.notNull)
      )
    elif column.typ.kind == dbFixedChar:
      # echo repr column
      let name = column.name
      let maxReprLen = column.typ.maxReprLen
      let notNull = column.typ.notNull
      let default = column.typ.validValues
      columnString.add(
        charGenerator(name, maxReprLen, notNull, default)
      )
    elif column.typ.kind == dbDate:
      columnString.add(
        dateGenerator(column.name, column.typ.notNull)
      )

  # primary key
  var primaryString = ""
  if primaryColumn.len > 0:
    primaryString.add(
      &", PRIMARY KEY ({primaryColumn})"
    )

  # create table
  var query =  &"CREATE TABLE {this.name} ({columnString}{primaryString})"
  
  var charset = getCharset()
  query.add(
    &" {charset}"
  )
  echo query
