import column
import ../util

type Table* = ref object
  name*: string
  columns*: seq[Column]


proc driverTypeError() =
  let driver = util.getDriver()
  if driver != "sqlite" and driver != "mysql" and driver != "postgres":
    raise newException(OSError, "invalid DB driver type")

proc create*(this:Table, name:string, columns:varargs[Column]): Table =
  driverTypeError()

  var table = Table(
    name: name,
    columns: @columns
  )

  return table
