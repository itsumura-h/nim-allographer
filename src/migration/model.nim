import db_common
import base, util, strformat
import
  migrates/sqlite_migrate,
  migrates/mysql_migrate
  # migrates/postgres_migrate
include ../database

export Model, Column


proc driverTypeError() =
  let driver = util.getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")


proc new*(this:Model, name:string, columns:varargs[Column]) =
  var newModel = Model(
    name: name,
    columns: @columns
  )

  driverTypeError()

  var query = ""
  let driver = util.getDriver()
  case driver:
    of "sqlite":
      query = sqlite_migrate.migrate(newModel)
    of "mysql":
      query = mysql_migrate.migrate(newModel)
    # of "postgres":
    #   query = postgres_migrate.migrate(newModel)
    else:
      echo ""
  echo query

  let table_name = newModel.name
  let db = db()
  try:
    db.exec(sql &"drop table {table_name}")
  except Exception:
    echo getCurrentExceptionMsg()

  try:
    db.exec(sql query)
  except Exception:
    echo getCurrentExceptionMsg()

  defer: db.close()


# proc migrate*(this: Model) =
#   driverTypeError()

#   var query = ""
#   let driver = util.getDriver()
#   case driver:
#     of "sqlite":
#       query = sqlite_migrate.migrate(this)
#     of "mysql":
#       query = mysql_migrate.migrate(this)
#     of "postgres":
#       query = postgres_migrate.migrate(this)
#     else:
#       echo ""
#   echo query

#   let table_name = this.name
#   let db = db()
#   try:
#     db.exec(sql &"drop table {table_name}")
#   except Exception:
#     echo getCurrentExceptionMsg()

#   try:
#     db.exec(sql query)
#   except Exception:
#     echo getCurrentExceptionMsg()

#   defer: db.close()
