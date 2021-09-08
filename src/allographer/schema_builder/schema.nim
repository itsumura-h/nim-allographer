import os, json, strutils, asyncdispatch, std/sha1, times
from strformat import `&`
import
  migrates/sqlite_migrate,
  migrates/mysql_migrate,
  migrates/postgres_migrate
import ../utils
import ../base
import ../async/async_db

import table


type MigrationTable* = ref object
  obj*:Table
  name*:string
  shouldRun*:bool
  query*:string
  indexQuery*:seq[string]
  queryHash*:string

type MigrationTables* = ref object
  recordPath*:string
  record*:JsonNode
  tables*:seq[MigrationTable]

proc new*(typ:type MigrationTables):MigrationTables =
  let self = MigrationTables()
  self.recordPath = getAppDir() / ".migration.json"
  self.record =
    if fileExists(self.recordPath):
      parseFile(self.recordPath)
    else:
      newJObject()
  return self

proc saveHash(self:MigrationTables, i:int) =
  let f = open(self.recordPath, FileMode.fmWrite)
  defer: f.close()
  self.record[self.tables[i].queryHash] = %*{
    "status": true,
    "query": self.tables[i].query & "; " & self.tables[i].indexQuery.join("; "),
    "run_at": now().format("yyyy-MM-dd HH:mm:ss")
  }
  f.write(self.record.pretty())

proc schema*(rdb:Rdb, tables:varargs[Table]) =
  let cmd = commandLineParams()
  let isReset = defined(reset) or cmd.contains("--reset")
  let migrationTables = MigrationTables.new()
  for table in tables:
    let query =
      case rdb.conn.driver:
      of SQLite3:
        sqlite_migrate.migrate(table)
      of MySQL:
        mysql_migrate.migrate(table)
      of MariaDB:
        mysql_migrate.migrate(table)
      of PostgreSQL:
        postgres_migrate.migrate(table)
    var indexQuery = newSeq[string]()
    for column in table.columns:
      if column.isIndex:
        let indexQueryRow =
          case rdb.conn.driver:
          of SQLite3:
            sqlite_migrate.createIndex(table.name, column.name)
          of MySQL:
            mysql_migrate.createIndex(table.name, column.name)
          of MariaDB:
            mysql_migrate.createIndex(table.name, column.name)
          of PostgreSQL:
            postgres_migrate.createIndex(table.name, column.name)
        indexQuery.add(indexQueryRow)
    let queryHash = $((query & indexQuery.join("; ")).secureHash())
    let shouldRun =
      if isReset:
        true
      elif migrationTables.record.hasKey(queryHash) and migrationTables.record[queryHash]["status"].getBool:
        false
      else:
        true

    migrationTables.tables.add(
      MigrationTable(obj:table, name:table.name, shouldRun:shouldRun,
        query:query, indexQuery:indexQuery, queryHash:queryHash)
    )

  for i in countdown(migrationTables.tables.len-1, 0): # reverse loop
    let table = migrationTables.tables[i]
    if table.shouldRun:
      try:
        var tableName = table.name
        wrapUpper(tableName, rdb.conn.driver)
        let query =
          if rdb.conn.driver == SQLite3:
            &"DROP TABLE IF EXISTS {tableName}"
          else:
            &"DROP TABLE IF EXISTS {tableName} CASCADE"
        rdb.log.logger(query)
        waitFor rdb.conn.exec(query)
      except:
        rdb.log.echoErrorMsg( getCurrentExceptionMsg() )

  for i, table in migrationTables.tables:
    if table.shouldRun:
      try:
        rdb.log.logger(table.query)
        waitFor rdb.conn.exec(table.query)
        migrationTables.saveHash(i)
      except:
        rdb.log.echoErrorMsg( getCurrentExceptionMsg() )

  # index
  for table in migrationTables.tables:
    if table.shouldRun:
      for row in table.indexQuery:
        rdb.log.logger(row)
        try:
          waitFor rdb.conn.exec(row)
        except:
          let err = getCurrentExceptionMsg()
          if err.contains("already exists"):
            rdb.log.echoErrorMsg(err)
            rdb.log.echoWarningMsg(&"Safety skip create table '{table.name}'")
          else:
            rdb.log.echoErrorMsg(err)
