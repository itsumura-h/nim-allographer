import strformat
import ../table
import ../column
import ../migrates/mysql_migrate
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

proc getColumns(table:string, previousName:string):string =
  let db = db()
  defer: db.close()
  var query = &"SHOW COLUMNS FROM {table}"
  var columns:string
  for i, row in db.getAllRows(sql query):
    if row[0] != previousName:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

proc change(column:Column, table:string) =
  let db = db()
  defer: db.close()
  let newColumnDifinition = generateColumnString(column)
  let query = &"ALTER TABLE {table} CHANGE `{column.previousName}` {newColumnDifinition}"
  logger(query)
  db.exec(sql query)

proc delete(column:Column, table:string) =
  let db = db()
  defer: db.close()
  let query = &"ALTER TABLE {table} DROP `{column.previousName}`"
  logger(query)
  db.exec(sql query)

proc rename(tableFrom, tableTo:string) =
  let db = db()
  defer: db.close()
  let query = &"ALTER TABLE {tableFrom} RENAME TO {tableTo}"
  logger(query)
  db.exec(sql query)

proc drop(table:string) =
  let db = db()
  defer: db.close()
  let query = &"DROP TABLE {table}"
  logger(query)
  db.exec(sql query)

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
