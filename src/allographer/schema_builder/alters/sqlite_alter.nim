import strformat, re, strutils
import ../table
import ../column
import ../migrates/sqlite_migrate
import ../../util
import ../../connection

proc add(column:Column, table:string) =
  let columnString = generateColumnString(column)
  let query = &"ALTER TABLE \"{table}\" ADD COLUMN {columnString}"
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
  let db = db()
  defer: db.close()
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table}';"
  var schema = db.getValue(sql tableDifinitionSql)
  schema = replace(schema, re"\)$", ",)")
  let columnRegex = &"'{column.previousName}'.*?,"
  let columnString = generateColumnString(column) & ","
  var query = replace(schema, re(columnRegex), columnString)
  query = replace(query, re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
  query = replace(query, re",\)", ")")
  logger(query)
  db.exec(sql query)
  query = &"INSERT INTO alter_table_tmp SELECT * FROM {table}"
  logger(query)
  db.exec(sql query)
  query = &"DROP TABLE {table}"
  logger(query)
  db.exec(sql query)
  query = &"ALTER TABLE alter_table_tmp RENAME TO {table}"
  logger(query)
  db.exec(sql query)


proc drop(column:Column, table:string) =
  let db = db()
  defer: db.close()
  let query = &"DROP TABLE {table}"


proc exec*(table:Table) =
  for column in table.columns:
    case column.alterTyp
    of Add:
      add(column, table.name)
    of Change:
      change(column, table.name)
    of Drop:
      drop(column, table.name)