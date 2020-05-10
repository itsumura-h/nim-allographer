import strformat, re, strutils
import ../table
import ../column
import ../migrates/mysql_migrate
import ../../util
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
  var query = &"ALTER TABLE {table} CHANGE `{column.previousName}` {newColumnDifinition}"
  logger(query)
  db.exec(sql query)

# proc getColumns(table:string, previousName:string):string =
#   let db = db()
#   defer: db.close()
#   var query = &"pragma table_info({table})"
#   var columns:string
#   for i, row in db.getAllRows(sql query):
#     if row[1] != previousName:
#       if i > 0: columns.add(", ")
#       columns.add(row[1])
#   return columns

proc delete(column:Column, table:string) =
  ## rename existing table as tmp
  ##
  ## create new table with existing table name
  ##
  ## copy data from tmp table to new table
  ##
  ## delete tmp table
  let db = db()
  defer: db.close()
  # rename existing table as tmp
  var query = &"ALTER TABLE {table} RENAME TO alter_table_tmp"
  logger(query)
  db.exec(sql query)
  # create new table with existing table name
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'alter_table_tmp';"
  var schema = db.getValue(sql tableDifinitionSql)
  schema = replace(schema, re"\)$", ",)")
  let columnRegex = &"'{column.previousName}'.*?,"
  query = replace(schema, re(columnRegex))
  query = replace(query, re",\)", ")")
  query = replace(query, re"alter_table_tmp", table)
  logger(query)
  db.exec(sql query)
  # copy data from tmp table to new table
  var columns = getColumns(table, column.previousName)
  query = &"INSERT INTO {table}({columns}) SELECT {columns} FROM alter_table_tmp"
  logger(query)
  db.exec(sql query)
  # delete tmp table
  query = &"DROP TABLE alter_table_tmp"
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
