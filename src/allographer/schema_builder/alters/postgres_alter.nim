import strformat, re, strutils, asyncdispatch
import ../table
import ../column
import ../migrates/postgres_migrate
import ../../utils
import ../../async/async_db

proc add(db:Connections, column:Column, table:string) =
  let querySeq = migrateAlter(table, column)
  block:
    try:
      for query in querySeq:
        logger(query)
        waitFor db.exec(query)
    except:
      let err = getCurrentExceptionMsg()
      echoErrorMsg(err)
      echoWarningMsg(&"Safety skip alter table '{table}'")

# proc getColumns(table:string, previousName:string):string =
#   let db = db()
#   defer: db.close()
#   var query = &"SELECT column_name FROM information_schema.columns WHERE table_name = {table} ORDER BY ordinal_position"

proc change(db:Connections, column:Column, table:string) =
  try:
    var columnString = generateColumnString(column)
    let columnTyp = columnString.split(" ")[1]
    # change column difinition
    var query = &"ALTER TABLE {table} ALTER COLUMN {column.previousName} TYPE {columnTyp}"
    logger(query)
    waitFor db.exec(query)
    # change column name
    query = &"ALTER TABLE {table} RENAME COLUMN {column.previousName} TO {column.name}"
    logger(query)
    waitFor db.exec(query)
    # delete option
    query = &"ALTER TABLE {table} ALTER {column.name} DROP DEFAULT"
    logger(query)
    waitFor db.exec(query)
    query = &"ALTER TABLE {table} ALTER {column.name} DROP NOT NULL"
    logger(query)
    waitFor db.exec(query)
    query = &"ALTER TABLE {table} DROP CONSTRAINT {table}_{column.previousName}"
    logger(query)
    waitFor db.exec(query)
    # set options
    if columnString.contains("DEFAULT"):
      let regex = """DEFAULT\s('.*'|\d)"""
      let defautSetting = findAll(columnString, re(regex))[0]
      query = &"ALTER TABLE {table} ALTER {column.name} SET {defautSetting}"
      logger(query)
      waitFor db.exec(query)
    if columnString.contains("NOT NULL"):
      query = &"ALTER TABLE {table} ALTER {column.name} SET NOT NULL"
      waitFor db.exec(query)
    if columnString.contains("CHECK"):
      let regex = "CHECK \\(.+?\\)"
      let checkSetting = findAll(columnString, re(regex))[0]
      query = &"ALTER TABLE {table} ADD CONSTRAINT {table}_{column.name} {checkSetting}"
      logger(query)
      waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc delete(db:Connections, column:Column, table:string) =
  try:
    let query = &"ALTER TABLE {table} DROP {column.previousName}"
    logger(query)
    waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc deleteColumn(db:Connections, table:string, column:Column) =
  try:
    let query = generateAlterDeleteQuery(table, column)
    logger(query)
    waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc deleteForeign(db:Connections, table:string, column:Column) =
  let querySeq = generateAlterDeleteForeignQueries(table, column)
  try:
    for query in querySeq:
      logger(query)
      waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc rename(db:Connections, tableFrom, tableTo:string) =
  try:
    let query = &"ALTER TABLE {tableFrom} RENAME TO {tableTo}"
    logger(query)
    waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc drop(db:Connections, table:string) =
  try:
    let query = &"DROP TABLE {table} CASCADE"
    logger(query)
    waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc exec*(db:Connections, table:Table) =
  if table.typ == Nomal:
    for column in table.columns:
      case column.alterTyp
      of Add:
        add(db, column, table.name)
      of Change:
        change(db, column, table.name)
      of Delete:
        if column.typ == rdbForeign:
          deleteForeign(db, table.name, column)
        else:
          deleteColumn(db, table.name, column)
  elif table.typ == Rename:
    rename(db, table.name, table.alterTo)
  elif table.typ == Drop:
    drop(db, table.name)
