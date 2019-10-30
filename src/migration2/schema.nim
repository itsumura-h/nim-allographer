import os, strformat, json
import
  migrates/sqlite_migrate,
  migrates/mysql_migrate,
  migrates/postgres_migrate
import ../util
include ../connection

import table


type Schema* = ref object
  tables*: seq[Table]


proc generateJsonSchema(tablesArg:varargs[Table]) =
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

  block:
    let f = open("tmp.json", FileMode.fmAppend)
    f.write(tables.pretty())
    defer:
      f.close()


proc create*(this:Schema, tables:varargs[Table]) =
  echo tryRemoveFile("tmp.json")
  generateJsonSchema(tables)

  for table in tables:
    # echo repr table

    var query = ""
    let driver = util.getDriver()
    case driver:
      of "sqlite":
        query = sqlite_migrate.migrate(table)
      of "mysql":
        query = mysql_migrate.migrate(table)
      of "postgres":
        query = postgres_migrate.migrate(table)
      else:
        echo ""
    logger(query)

    let table_name = table.name

    block:
      let db = db()
      # try:
      #   db.exec(sql &"drop table {table_name}")
      # except Exception:
      #   echo getCurrentExceptionMsg()

      try:
        db.exec(sql query)
      except Exception:
        echo getCurrentExceptionMsg()

      defer: db.close()