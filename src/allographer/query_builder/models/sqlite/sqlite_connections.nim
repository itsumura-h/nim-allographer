import std/json
import ./sqlite_types


proc `$`*(self:SqliteConnections|SqliteQuery):string =
  return "SQLite3"


proc select*(self:SqliteConnections, columnsArg:varargs[string]):SqliteQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let sqliteQuery = SqliteQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return sqliteQuery


proc table*(self:SqliteConnections, tableArg: string): SqliteQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let sqliteQuery = SqliteQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return sqliteQuery


proc raw*(self:SqliteConnections, sql:string, arges=newJArray()): RawSqliteQuery =
  ## arges is `JArray`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawSqliteQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: newJObject(),
    queryString: sql,
    placeHolder: arges,
    isInTransaction: false,
    transactionConn: 0
  )
  return rawQueryRdb
