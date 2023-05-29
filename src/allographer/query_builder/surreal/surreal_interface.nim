import std/asyncdispatch
import std/json
import ../log
import ./surreal_types
import ./query/exec


# ==================== Private ====================
proc getAllRows(self:SurrealDb | RawQuerySurrealDb, queryString:string, args:seq[string]):Future[JsonNode] {.async.} =
  let rows = self.conn.query(
    queryString,
    args,
    self.isInTransaction,
    self.transactionConn
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString & $args)
    return newJArray()
  return rows

# ==================== Public ====================
proc get*(self: RawQuerySurrealDb):Future[JsonNode]{.async.} =
  ## It is only used with raw()
  try:
    self.log.logger(self.queryString, self.placeHolder)
    return getAllRows(self, self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newJArray()


proc exec*(self: RawQuerySurrealDb){.async.} =
  ## It is only used with raw()
  try:
    self.log.logger(self.queryString, self.placeHolder)
    self.conn.exec(self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
