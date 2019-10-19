import db_common, strformat, strutils, json
import base
import util, generators
import migrates/sqlite_migrate
include ../modules/database

export Model, Column

proc new*(this:Model, name:string, columns:varargs[Column]): Model =
  Model(
    name: name,
    columns: @columns
  )

proc driverTypeError() =
  let driver = util.getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")

proc migrate*(this: Model) =
  driverTypeError()

  var columnString = ""
  let driver = util.getDriver()
  case driver:
    of "sqlite":
      columnString.add(
        sqlite_migrate.migrate(this)
      )
    of "mysql":
      columnString.add(
        ""
      )
    of "postgres":
      columnString.add(
        ""
      )
    else:
      echo ""
  echo columnString
