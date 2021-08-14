import strformat, asyncdispatch
import ../table
import ../column
import ../migrates/mysql_migrate
import ../../utils
import ../../async/async_db
import ../../base

proc add(rdb:Rdb, column:Column, table:string) =
  # let columnString = generateColumnString(column)
  # let query = &"ALTER TABLE {table} ADD {columnString}"
  let querySeq = generateAlterAddQueries(column, table)
  block:
    try:
      for query in querySeq:
        rdb.log.logger(query)
        waitFor rdb.db.exec(query)
    except:
      let err = getCurrentExceptionMsg()
      rdb.log.echoErrorMsg(err)
      rdb.log.echoWarningMsg(&"Safety skip alter table '{table}'")

proc getColumns(db:Connections, table:string, name:string):string =
  var query = &"SHOW COLUMNS FROM {table}"
  var columns:string
  let (rows, _) = waitFor db.query(query)
  for i, row in rows:
    if row[0] != name:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

proc change(rdb:Rdb, column:Column, table:string) =
  try:
    let newColumnDifinition = generateColumnString(column)
    let query = &"ALTER TABLE {table} CHANGE `{column.previousName}` {newColumnDifinition}"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc deleteColumn(rdb:Rdb, table:string, column:Column) =
  try:
    let query = generateAlterDeleteQuery(table, column)
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc deleteForeign(rdb:Rdb, table:string, column:Column) =
  let querySeq = generateAlterDeleteForeignQueries(table, column)
  try:
    for query in querySeq:
      rdb.log.logger(query)
      waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc rename(rdb:Rdb, tableFrom, tableTo:string) =
  try:
    let query = &"ALTER TABLE {tableFrom} RENAME TO {tableTo}"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc drop(rdb:Rdb, table:string) =
  try:
    let query = &"DROP TABLE {table}"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc exec*(rdb:Rdb, table:Table) =
  if table.typ == Nomal:
    for column in table.columns:
      case column.alterTyp
      of Add:
        add(rdb, column, table.name)
      of Change:
        change(rdb, column, table.name)
      of Delete:
        if column.typ == rdbForeign:
          deleteForeign(rdb, table.name, column)
        else:
          deleteColumn(rdb, table.name, column)
  elif table.typ == Rename:
    rename(rdb, table.name, table.alterTo)
  elif table.typ == Drop:
    drop(rdb, table.name)
