import db_common
import base, util, strformat
import migrates/sqlite_migrate, migrates/mysql_migrate
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

  var query = ""
  let driver = util.getDriver()
  case driver:
    of "sqlite":
      query = sqlite_migrate.migrate(this)
    of "mysql":
      query = mysql_migrate.migrate(this)
    of "postgres":
      query = ""
    else:
      echo ""
  echo query

  let table_name = this.name
  let db = db()
  try:
    db.exec(sql &"drop table {table_name}")
    db.exec(sql query)
  except Exception:
    echo getCurrentExceptionMsg()

  defer: db.close()