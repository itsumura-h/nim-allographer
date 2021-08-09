import strformat, re, asyncdispatch
import ../table
import ../column
import ../migrates/sqlite_migrate
import ../../utils
# import ../../connection
import ../../async/async_db

proc add(db:Connections, column:Column, table:string) =
  let query = migrateAlter(column, table)
  logger(query)
  block:
    try:
      waitFor db.exec(query)
    except:
      let err = getCurrentExceptionMsg()
      echoErrorMsg(err)
      echoWarningMsg(&"Safety skip alter table '{table}'")

proc change(db:Connections, column:Column, table:string) =
  ## create tmp table with new column difinition
  ##
  ## copy data from existing table to tmp table
  ##
  ## delete existing table
  ##
  ## rename tmp table to existing table
  try:
    # create tmp table with new column difinition
    #   get existing table schema
    let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table}';"
    var (row, columns) = waitFor db.query(tableDifinitionSql)
    let schema = replace(row[0][0], re"\)$", ",)")
    let columnRegex = &"'{column.previousName}'.*?,"
    let columnString = generateColumnString(column) & ","
    var query = replace(schema, re(columnRegex), columnString)
    query = replace(query, re",\)", ")")
    query = replace(query, re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
    logger(query)
    waitFor db.exec(query)
    # copy data from existing table to tmp table
    query = &"INSERT INTO alter_table_tmp SELECT * FROM {table}"
    logger(query)
    waitFor db.exec(query)
    # delete existing table
    query = &"DROP TABLE {table}"
    logger(query)
    waitFor db.exec(query)
    # rename tmp table to existing table
    query = &"ALTER TABLE alter_table_tmp RENAME TO {table}"
    logger(query)
    waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

proc getColumns(db:Connections, table:string, previousName:string):string =
  var query = &"pragma table_info({table})"
  var columns:string
  let (rows, _) = waitFor db.query(query)
  for i, row in rows:
    if row[1] != previousName:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

proc deleteColumn(db:Connections, column:Column, table:string) =
  ## rename existing table as tmp
  ##
  ## create new table with existing table name
  ##
  ## copy data from tmp table to new table
  ##
  ## delete tmp table
  try:
    # delete tmp table
    let query = &"DROP TABLE alter_table_tmp"
    logger(query)
    waitFor db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    echoErrorMsg(err)

  try:
    # rename existing table as tmp
    var query = &"ALTER TABLE \"{table}\" RENAME TO 'alter_table_tmp'"
    logger(query)
    waitFor db.exec(query)
    # create new table with existing table name
    let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'alter_table_tmp';"
    var (rows, _) = waitFor db.query(tableDifinitionSql)
    let schema = replace(rows[0][0], re"\)$", ",)")
    let columnRegex = &"'{column.name}'.*?,"
    query = replace(schema, re(columnRegex))
    query = replace(query, re"alter_table_tmp", table)
    query = replace(query, re",\s*\)", ")")
    logger(query)
    waitFor db.exec(query)
    # copy data from tmp table to new table
    var columns = db.getColumns(table, column.name)
    query = &"INSERT INTO {table}({columns}) SELECT {columns} FROM alter_table_tmp"
    logger(query)
    waitFor db.exec(query)
    # delete tmp table
    query = &"DROP TABLE alter_table_tmp"
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
    let query = &"DROP TABLE {table}"
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
        deleteColumn(db, column, table.name)

  elif table.typ == Rename:
    rename(db, table.name, table.alterTo)
  elif table.typ == Drop:
    drop(db, table.name)
