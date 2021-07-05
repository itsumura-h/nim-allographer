import strformat, re, strutils
import ../table
import ../column
import ../migrates/postgres_migrate
import ../../utils
import ../../connection

proc add(column:Column, table:string) =
  let columnString = generateColumnString(column)
  let query = &"ALTER TABLE {table} ADD {columnString}"
  logger(query)
  block:
    let db = db()
    defer: db.close()
    try:
      db.exec(sql query)
    except:
      let err = getCurrentExceptionMsg()
      echoErrorMsg(err)
      echoWarningMsg(&"Safety skip alter table '{table}'")

# proc getColumns(table:string, previousName:string):string =
#   let db = db()
#   defer: db.close()
#   var query = &"SELECT column_name FROM information_schema.columns WHERE table_name = {table} ORDER BY ordinal_position"

proc change(column:Column, table:string) =
  let db = db()
  defer: db.close()
  try:
    var columnString = generateColumnString(column)
    let columnTyp = columnString.split(" ")[1]
    # change column difinition
    var query = &"ALTER TABLE {table} ALTER COLUMN {column.previousName} TYPE {columnTyp}"
    logger(query)
    db.exec(sql query)
    # change column name
    query = &"ALTER TABLE {table} RENAME COLUMN {column.previousName} TO {column.name}"
    logger(query)
    db.exec(sql query)
    # delete option
    query = &"ALTER TABLE {table} ALTER {column.name} DROP DEFAULT"
    logger(query)
    db.exec(sql query)
    query = &"ALTER TABLE {table} ALTER {column.name} DROP NOT NULL"
    logger(query)
    db.exec(sql query)
    query = &"ALTER TABLE {table} DROP CONSTRAINT {table}_{column.previousName}"
    logger(query)
    db.exec(sql query)
    # set options
    if columnString.contains("DEFAULT"):
      let regex = """DEFAULT\s('.*'|\d)"""
      let defautSetting = findAll(columnString, re(regex))[0]
      query = &"ALTER TABLE {table} ALTER {column.name} SET {defautSetting}"
      logger(query)
      db.exec(sql query)
    if columnString.contains("NOT NULL"):
      query = &"ALTER TABLE {table} ALTER {column.name} SET NOT NULL"
      db.exec(sql query)
    if columnString.contains("CHECK"):
      let regex = "CHECK \\(.+?\\)"
      let checkSetting = findAll(columnString, re(regex))[0]
      query = &"ALTER TABLE {table} ADD CONSTRAINT {table}_{column.name} {checkSetting}"
      logger(query)
      db.exec(sql query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc delete(column:Column, table:string) =
  let db = db()
  defer: db.close()
  try:
    let query = &"ALTER TABLE {table} DROP {column.previousName}"
    logger(query)
    db.exec(sql query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc rename(tableFrom, tableTo:string) =
  let db = db()
  defer: db.close()
  try:
    let query = &"ALTER TABLE {tableFrom} RENAME TO {tableTo}"
    logger(query)
    db.exec(sql query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc drop(table:string) =
  let db = db()
  defer: db.close()
  try:
    let query = &"DROP TABLE {table}"
    logger(query)
    db.exec(sql query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc exec*(table:Table) =
  if table.typ == Nomal:
    for column in table.columns:
      case column.alterTyp
      of Add:
        add(column, table.name)
      of Change:
        change(column, table.name)
      of Delete:
        delete(column, table.name)
  elif table.typ == Rename:
    rename(table.name, table.alterTo)
  elif table.typ == Drop:
    drop(table.name)
