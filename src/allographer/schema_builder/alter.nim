import json, strformat
import ./table, ./column
import ./alters/sqlite_alter
import ../util
import ../connection


proc alter*(tables:varargs[Table]) =
  for table in tables:

    var query = ""
    let driver = getDriver()
    # case driver:
    # of "sqlite":
    #   query = sqlite_alter.generate(table)
    # of "mysql":
    #   query = mysql_alter.generate(table)
    # of "postgres":
    #   query = postgres_alter.generate(table)
    query = sqlite_alter.generate(table)
    echo query

    # logger(query)

    block:
      let db = db()
      defer: db.close()
      try:
        db.exec(sql query)
      except:
        let err = getCurrentExceptionMsg()
        echoErrorMsg(err)
        echoWarningMsg(&"Safety skip alter table '{table.name}'")

proc add*():Column =
  return Column(alterTyp:Add)

proc change*(name:string):Column =
  return Column(alterTyp:Change, name:name)

proc drop*(name:string):Column =
  return Column(alterTyp:Drop, name:name)

proc rename*(alterFrom, alterTo:string):Table =
  return Table(
    name:alterFrom,
    alterTo:alterTo
  )
