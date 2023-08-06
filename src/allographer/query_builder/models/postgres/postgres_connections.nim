import std/json
import ./postgres_types


proc `$`*(self:PostgresConnections|PostgresQuery):string =
  return "PostgreSQL"


proc select*(self:PostgresConnections, columnsArg:varargs[string]):PostgresQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let postgresQuery = PostgresQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: query,
    queryString: "",
    placeHolder: newJArray()
  )
  return postgresQuery


proc table*(self:PostgresConnections, tableArg: string): PostgresQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let postgresQuery = PostgresQuery(
    log: self.log,
    pools: self.pools,
    timeout: self.timeout,
    query: query,
    queryString: "",
    placeHolder: newJArray()
  )
  return postgresQuery


proc raw*(self:PostgresConnections, sql:string, arges=newJArray()): RawPostgresQuery =
  ## arges is `JArray`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawPostgresQuery(
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
