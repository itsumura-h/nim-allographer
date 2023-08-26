import std/json
import ./mariadb_types


proc `$`*(self:MariadbConnections|MariadbQuery):string =
  return "PostgreSQL"


proc select*(self:MariadbConnections, columnsArg:varargs[string]):MariadbQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let MariadbQuery = MariadbQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: query,
    queryString: "",
    placeHolder: newJArray()
  )
  return MariadbQuery


proc table*(self:MariadbConnections, tableArg: string): MariadbQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let MariadbQuery = MariadbQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: query,
    queryString: "",
    placeHolder: newJArray()
  )
  return MariadbQuery


proc raw*(self:MariadbConnections, sql:string, arges=newJArray()): RawMariadbQuery =
  ## arges is `JArray` `[true, 1, 1.1, "str"]`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawMariadbQuery(
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
