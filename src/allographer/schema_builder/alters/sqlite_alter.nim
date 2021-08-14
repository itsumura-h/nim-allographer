import strformat, re, asyncdispatch
import ../table
import ../column
import ../migrates/sqlite_migrate
import ../../utils
# import ../../connection
import ../../base
import ../../async/async_db

proc add(rdb:Rdb, column:Column, table:string) =
  let query = migrateAlter(column, table)
  rdb.log.logger(query)
  block:
    try:
      waitFor rdb.db.exec(query)
    except:
      let err = getCurrentExceptionMsg()
      rdb.log.echoErrorMsg(err)
      rdb.log.echoWarningMsg(&"Safety skip alter table '{table}'")

proc change(rdb:Rdb, column:Column, table:string) =
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
    var (row, columns) = waitFor rdb.db.query(tableDifinitionSql)
    let schema = replace(row[0][0], re"\)$", ",)")
    let columnRegex = &"'{column.previousName}'.*?,"
    let columnString = generateColumnString(column) & ","
    var query = replace(schema, re(columnRegex), columnString)
    query = replace(query, re",\)", ")")
    query = replace(query, re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
    # copy data from existing table to tmp table
    query = &"INSERT INTO alter_table_tmp SELECT * FROM {table}"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
    # delete existing table
    query = &"DROP TABLE {table}"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
    # rename tmp table to existing table
    query = &"ALTER TABLE alter_table_tmp RENAME TO {table}"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

proc getColumns(db:Connections, table:string, previousName:string):string =
  var query = &"pragma table_info({table})"
  var columns:string
  let (rows, _) = waitFor db.query(query)
  for i, row in rows:
    if row[1] != previousName:
      if i > 0: columns.add(", ")
      columns.add(row[1])
  return columns

proc deleteColumn(rdb:Rdb, column:Column, table:string) =
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
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
  except:
    let err = getCurrentExceptionMsg()
    rdb.log.echoErrorMsg(err)

  try:
    # rename existing table as tmp
    var query = &"ALTER TABLE \"{table}\" RENAME TO 'alter_table_tmp'"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
    # create new table with existing table name
    let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'alter_table_tmp';"
    var (rows, _) = waitFor rdb.db.query(tableDifinitionSql)
    let schema = replace(rows[0][0], re"\)$", ",)")
    let columnRegex = &"'{column.name}'.*?,"
    query = replace(schema, re(columnRegex))
    query = replace(query, re"alter_table_tmp", table)
    query = replace(query, re",\s*\)", ")")
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
    # copy data from tmp table to new table
    var columns = rdb.db.getColumns(table, column.name)
    query = &"INSERT INTO {table}({columns}) SELECT {columns} FROM alter_table_tmp"
    rdb.log.logger(query)
    waitFor rdb.db.exec(query)
    # delete tmp table
    query = &"DROP TABLE alter_table_tmp"
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
        deleteColumn(rdb, column, table.name)

  elif table.typ == Rename:
    rename(rdb, table.name, table.alterTo)
  elif table.typ == Drop:
    drop(rdb, table.name)
