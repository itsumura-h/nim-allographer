import strformat, asyncdispatch
import ../table
import ../column
import ../migrates/mysql_migrate
import ../../utils
import ../../async/async_db

proc add(db:Connections, column:Column, table:string) =
  # let columnString = generateColumnString(column)
  # let query = &"ALTER TABLE {table} ADD {columnString}"
  let querySeq = generateAlterAddQueries(column, table)
  block:
    try:
      for query in querySeq:
        logger(query)
        waitFor db.exec(query)
    except:
      let err = getCurrentExceptionMsg()
      echoErrorMsg(err)
      echoWarningMsg(&"Safety skip alter table '{table}'")

proc getColumns(db:Connections, table:string, name:string):string =
  var query = &"SHOW COLUMNS FROM {table}"
  var columns:string
  let (rows, _) = waitFor db.query(query)
  for i, row in rows:
    if row[0] != name:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

proc change(db:Connections, column:Column, table:string) =
  try:
    let newColumnDifinition = generateColumnString(column)
    let query = &"ALTER TABLE {table} CHANGE `{column.previousName}` {newColumnDifinition}"
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
        if column.typ == rdbForeign:
          deleteForeign(db, table.name, column)
        else:
          deleteColumn(db, table.name, column)
  elif table.typ == Rename:
    rename(db, table.name, table.alterTo)
  elif table.typ == Drop:
    drop(db, table.name)
