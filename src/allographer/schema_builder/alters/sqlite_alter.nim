import strformat, re
import ../table
import ../column
import ../migrates/sqlite_migrate
import ../../utils
import ../../connection

proc add(column:Column, table:string) =
  let query = migrateAlter(column, table)
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
  ## create tmp table with new column difinition
  ##
  ## copy data from existing table to tmp table
  ##
  ## delete existing table
  ##
  ## rename tmp table to existing table
  let db = db()
  defer: db.close()
  try:
    # create tmp table with new column difinition
    #   get existing table schema
    let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table}';"
    var schema = db.getValue(sql tableDifinitionSql)
    schema = replace(schema, re"\)$", ",)")
    let columnRegex = &"'{column.previousName}'.*?,"
    let columnString = generateColumnString(column) & ","
    var query = replace(schema, re(columnRegex), columnString)
    query = replace(query, re",\)", ")")
    query = replace(query, re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
    logger(query)
    db.exec(sql query)
    # copy data from existing table to tmp table
    query = &"INSERT INTO alter_table_tmp SELECT * FROM {table}"
    logger(query)
    db.exec(sql query)
    # delete existing table
    query = &"DROP TABLE {table}"
    logger(query)
    db.exec(sql query)
    # rename tmp table to existing table
    query = &"ALTER TABLE alter_table_tmp RENAME TO {table}"
    logger(query)
    db.exec(sql query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc getColumns(table:string, previousName:string):string =
  let db = db()
  defer: db.close()
  var query = &"pragma table_info({table})"
  var columns:string
  for i, row in db.getAllRows(sql query):
    if row[1] != previousName:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

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
  try:
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
