import strformat
import ../table
import ../column
import ../migrates/sqlite_migrate
import ../../util
import ../../connection

proc add(column:Column, table:string) =
  let columnString = generateColumnString(column)
  let query = &"ALTER TABLE {table} ADD COLUMN {columnString}"
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

proc change(column:Column, table:string) =
  let tableDifinitionSql = &"select sql from sqlite_master where type = 'table' and name = '{table}';"

proc drop(column:Column, table:string) =
  let sql = &"ALTER TABLE {table} DROP {column.name}"


proc exec*(table:Table) =
  for column in table.columns:
    case column.alterTyp
    of Add:
      add(column, table.name)
    of Change:
      change(column, table.name)
    of Drop:
      drop(column, table.name)