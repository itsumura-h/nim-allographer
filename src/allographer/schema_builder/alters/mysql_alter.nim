import strformat
import ../table
import ../column
import ../migrates/mysql_migrate
import ../../utils
import ../../connection

proc add(column:Column, table:string) =
  # let columnString = generateColumnString(column)
  # let query = &"ALTER TABLE {table} ADD {columnString}"
  let querySeq = migrateAlter(column, table)
  block:
    let db = db()
    defer: db.close()
    try:
      for query in querySeq:
        logger(query)
        db.exec(sql query)
    except:
      let err = getCurrentExceptionMsg()
      echoErrorMsg(err)
      echoWarningMsg(&"Safety skip alter table '{table}'")

proc getColumns(table:string, name:string):string =
  let db = db()
  defer: db.close()
  var query = &"SHOW COLUMNS FROM {table}"
  var columns:string
  for i, row in db.getAllRows(sql query):
    if row[0] != name:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

proc change(column:Column, table:string) =
  let db = db()
  defer: db.close()
  try:
    let newColumnDifinition = generateColumnString(column)
    let query = &"ALTER TABLE {table} CHANGE `{column.name}` {newColumnDifinition}"
    logger(query)
    db.exec(sql query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc delete(column:Column, table:string) =
  let db = db()
  defer: db.close()
  try:
    let query = &"ALTER TABLE {table} DROP `{column.name}`"
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
        if column.typ == rdbForeign:
          delete(column, table.name)
        else:
          delete(column, table.name)
  elif table.typ == Rename:
    rename(table.name, table.alterTo)
  elif table.typ == Drop:
    drop(table.name)
