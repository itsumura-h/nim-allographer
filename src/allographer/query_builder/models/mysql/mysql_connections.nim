import std/json
import std/strutils
import ./mysql_types


proc `$`*(self:MysqlConnections|MysqlQuery):string =
  return "PostgreSQL"


proc select*(self:MysqlConnections, columnsArg:varargs[string]):MysqlQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let MysqlQuery = MysqlQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    info: self.info,
    query: query,
    queryString: "",
    placeHolder: newJArray()
  )
  return MysqlQuery


proc table*(self:MysqlConnections, tableArg: string): MysqlQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let MysqlQuery = MysqlQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    info: self.info,
    query: query,
    queryString: "",
    placeHolder: newJArray()
  )
  return MysqlQuery


proc raw*(self:MysqlConnections, sql:string, arges=newJArray()): RawMysqlQuery =
  ## arges is `JArray` `[true, 1, 1.1, "str"]`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawMysqlQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    info: self.info,
    query: newJObject(),
    queryString: sql.strip(),
    placeHolder: arges,
    isInTransaction: false,
    transactionConn: 0
  )
  return rawQueryRdb
