import std/json
import std/strutils
import ./surreal_types


proc `$`*(self:SurrealConnections|SurrealQuery):string =
  return "PostgreSQL"


proc select*(self:SurrealConnections, columnsArg:varargs[string]):SurrealQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let surrealQuery = SurrealQuery.new(
    self.log,
    self.pools,
    self.timeout,
    query
  )
  return surrealQuery


proc table*(self:SurrealConnections, tableArg: string): SurrealQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let surrealQuery = SurrealQuery.new(
    self.log,
    self.pools,
    self.timeout,
    query,
  )
  return surrealQuery


proc raw*(self:SurrealConnections, sql:string, arges=newJArray()): RawSurrealQuery =
  ## arges is `JArray`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawSurrealQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: newJObject(),
    queryString: sql.strip(),
    placeHolder: arges,
  )
  return rawQueryRdb
