import json, strformat
import ./table, ./column
import
  ./alters/sqlite_alter,
  ./alters/mysql_alter,
  ./alters/postgres_alter
import ../util
import ../connection


proc alter*(tables:varargs[Table]) =
  for table in tables:
    let driver = getDriver()
    case driver:
    of "sqlite":
      sqlite_alter.exec(table)
    of "mysql":
      mysql_alter.exec(table)
    of "postgres":
      postgres_alter.exec(table)

    # logger(query)

  # block:
  #   let db = db()
  #   defer: db.close()
  #   try:
  #     for query in queries:
  #       db.exec(sql query)
  #   except:
  #     let err = getCurrentExceptionMsg()
  #     echoErrorMsg(err)
  #     echoWarningMsg(&"Safety skip alter table '{table.name}'")

proc add*():Column =
  return Column(alterTyp:Add)

proc change*(name:string):Column =
  return Column(alterTyp:Change, previousName:name)

proc drop*(name:string):Column =
  return Column(alterTyp:Drop, previousName:name)

proc rename*(alterFrom, alterTo:string):Table =
  return Table(
    name:alterFrom,
    alterTo:alterTo
  )
