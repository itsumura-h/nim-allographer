import os, json, strutils
from strformat import `&`
import
  migrates/sqlite_migrate,
  migrates/mysql_migrate,
  migrates/postgres_migrate
import ../util
import ../connection

import table


type
  Schema* = ref object
    tables*: seq[Table]

  # AlterType* = enum
  #   ADD = "add"
  #   CHANGE = "change"
  #   DROP = "drop"

proc generateJsonSchema(tablesArg:varargs[Table]):JsonNode =
  var tables = %*[]
  for table in tablesArg:

    var columns = %*[]
    for column in table.columns:
      columns.add(%*{
        "name": column.name,
        "typ": column.typ,
        "isNullable": column.isNullable,
        "isUnsigned": column.isUnsigned,
        "isDefault": column.isDefault,
        "defaultBool": column.defaultBool,
        "defaultInt": column.defaultInt,
        "defaultFloat": column.defaultFloat,
        "defaultString": column.defaultString,
        "foreignOnDelete": column.foreignOnDelete,
        "info": if column.info != nil: $column.info else: ""
      })

    tables.add(
      %*{"name": table.name, "columns": columns}
    )

  return tables


proc checkDiff(path:string, newTables:JsonNode) =
  # load json
  var diffs = %*[]
  let oldTables = parseFile(path)
  for i, oldTable in oldTables.getElems:
    var newTable = newTables[i]
    if oldTable["name"].getStr != newTable["name"].getStr:
      diffs.add(
        %*{"name": newTable["name"].getStr}
      )


proc generateMigrationFile(path:string, tablesArg:JsonNode) =
  block:
    let f = open(path, FileMode.fmWrite)
    f.write(tablesArg.pretty())
    defer: f.close()


proc check*(this:Schema, tablesArg:varargs[Table]) =
  let tablesJson = generateJsonSchema(tablesArg)
  const path = "migration.json"
  if fileExists(path):
    checkDiff(path, tablesJson)
    # generateMigrationFile(path, tablesJson)
  else:
    generateMigrationFile(path, tablesJson)

# =============================================================================

proc schema*(tables:varargs[Table]) =
  driverTypeError()

  block:
    var deleteList: seq[string]
    for table in tables:
      if table.reset:
        deleteList.add(table.name)
    # delete table in reverse loop
    let db = db()
    for i, v in deleteList:
      var index = i+1
      try:
        db.exec(sql &"drop table {deleteList[^index]}")
      except Exception:
        getCurrentExceptionMsg().echoErrorMsg()
    defer: db.close()

  for table in tables:
    var query = ""
    let driver = getDriver()
    case driver:
    of "sqlite":
      query = sqlite_migrate.migrate(table)
    of "mysql":
      query = mysql_migrate.migrate(table)
    of "postgres":
      query = postgres_migrate.migrate(table)

    logger(query)

    block:
      let db = db()
      defer: db.close()
      try:
        db.exec(sql query)
      except:
        let err = getCurrentExceptionMsg()
        if err.contains("already exists"):
          echoErrorMsg(err)
          echoWarningMsg(&"Safety skip create table '{table.name}'")
