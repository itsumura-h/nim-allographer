import std/json
import std/strutils
import ./mariadb_types


proc `$`*(self:MariadbConnections|MariadbQuery):string =
  return "PostgreSQL"


proc select*(self:MariadbConnections, columnsArg:varargs[string]):MariadbQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let mariadbQuery = MariadbQuery(
    log: self.log,
    pools: self.pools,
    info: self.info,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return mariadbQuery


proc table*(self:MariadbConnections, tableArg: string): MariadbQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let mariadbQuery = MariadbQuery(
    log: self.log,
    pools: self.pools,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return mariadbQuery


proc raw*(self:MariadbConnections, sql:string, arges=newJArray()): RawMariadbQuery =
  ## arges is `JArray` `[true, 1, 1.1, "str"]`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawMariadbQuery(
    log: self.log,
    pools: self.pools,
    info: self.info,
    query: newJObject(),
    queryString: sql.strip(),
    placeHolder: arges,
    isInTransaction: false,
    transactionConn: 0
  )
  return rawQueryRdb
