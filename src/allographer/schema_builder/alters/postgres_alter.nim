import strformat, re, strutils, asyncdispatch
import ../table
import ../column
import ../migrates/postgres_migrate
import ../../utils
import ../../async/async_db
import ../../base

proc add(rdb:Rdb, column:Column, table:string) =
  let querySeq = migrateAlter(table, column)
  block:
    try:
      for query in querySeq:
        rdb.log.logger(query)
        waitFor rdb.conn.exec(query)
    except:
      let err = getCurrentExceptionMsg()
      rdb.log.echoErrorMsg(err)
      rdb.log.echoWarningMsg(&"Safety skip alter table '{table}'")

# proc getColumns(table:string, previousName:string):string =
#   let db = db()
#   defer: db.close()
#   var query = &"SELECT column_name FROM information_schema.columns WHERE table_name = {table} ORDER BY ordinal_position"

proc change(rdb:Rdb, column:Column, table:string) =
  try:
    var columnString = generateColumnString(column)
    let columnTyp = columnString.split(" ")[1]
    # change column difinition
    var query = &"ALTER TABLE {table} ALTER COLUMN {column.previousName} TYPE {columnTyp}"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
    # change column name
    query = &"ALTER TABLE {table} RENAME COLUMN {column.previousName} TO {column.name}"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
    # delete option
    query = &"ALTER TABLE {table} ALTER {column.name} DROP DEFAULT"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
    query = &"ALTER TABLE {table} ALTER {column.name} DROP NOT NULL"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
    query = &"ALTER TABLE {table} DROP CONSTRAINT {table}_{column.previousName}"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
    # set options
    if columnString.contains("DEFAULT"):
      let regex = """DEFAULT\s('.*'|\d)"""
      let defautSetting = findAll(columnString, re(regex))[0]
      query = &"ALTER TABLE {table} ALTER {column.name} SET {defautSetting}"
      rdb.log.logger(query)
      waitFor rdb.conn.exec(query)
    if columnString.contains("NOT NULL"):
      query = &"ALTER TABLE {table} ALTER {column.name} SET NOT NULL"
      waitFor rdb.conn.exec(query)
    if columnString.contains("CHECK"):
      let regex = "CHECK \\(.+?\\)"
      let checkSetting = findAll(columnString, re(regex))[0]
      query = &"ALTER TABLE {table} ADD CONSTRAINT {table}_{column.name} {checkSetting}"
      rdb.log.logger(query)
      waitFor rdb.conn.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc delete(rdb:Rdb, column:Column, table:string) =
  try:
    let query = &"ALTER TABLE {table} DROP {column.previousName}"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc deleteColumn(rdb:Rdb, table:string, column:Column) =
  try:
    let query = generateAlterDeleteQuery(table, column)
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc deleteForeign(rdb:Rdb, table:string, column:Column) =
  let querySeq = generateAlterDeleteForeignQueries(table, column)
  try:
    for query in querySeq:
      rdb.log.logger(query)
      waitFor rdb.conn.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc rename(rdb:Rdb, tableFrom, tableTo:string) =
  try:
    let query = &"ALTER TABLE {tableFrom} RENAME TO {tableTo}"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc drop(rdb:Rdb, table:string) =
  try:
    let query = &"DROP TABLE {table} CASCADE"
    rdb.log.logger(query)
    waitFor rdb.conn.exec(query)
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
