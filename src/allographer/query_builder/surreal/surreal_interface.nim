import std/asyncdispatch
import std/json
import std/options
import std/sequtils
import ../log
import ./surreal_types
import ./query/builder
import ./query/exec


# ==================== Private ====================
proc getAllRows(self:SurrealDb | RawQuerySurrealDb, queryString:string, args:seq[string]):Future[seq[JsonNode]] {.async.} =
  let rows = self.conn.query(
    queryString,
    args,
    self.isInTransaction,
    self.transactionConn
  ).await
  if rows.len == 0:
    self.log.echoErrorMsg(queryString, args)
    return newSeq[JsonNode]()
  return rows.toSeq()


proc getRow(self:SurrealDb | RawQuerySurrealDb, queryString:string, args:seq[string]):Future[Option[JsonNode]] {.async.} =
  let rows = self.conn.query(
    queryString,
    args,
    self.isInTransaction,
    self.transactionConn
  ).await
  if rows.len == 0:
    self.log.echoErrorMsg(queryString, args)
    return none(JsonNode)
  return rows[0].some


# ==================== Public ====================
proc get*(self: SurrealDb):Future[seq[JsonNode]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getAllRows(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode]()


proc first*(self: SurrealDb):Future[Option[JsonNode]] {.async.} =
  # defer: self.cleanUp()
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


proc find*(self: SurrealDb, id: string, key="id"):Future[Option[JsonNode]]{.async.} =
  # defer: self.cleanUp()
  self.placeHolder.add(id)
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


# ==================== INSERT ====================

proc insert*(self: SurrealDb, items: JsonNode){.async.} =
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


proc insert*(self: SurrealDb, rows: seq[JsonNode]){.async.} =
  let sql = self.insertValuesBuilder(rows)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


proc insertId*(self: SurrealDb, items: JsonNode, key="id"):Future[string] {.async.} =
  let sql = self.insertValueBuilder(items)
  let res = getRow(self, sql, self.placeHolder).await
  if res.isSome():
    return res.get()[key].getStr()
  else:
    return ""


proc insertId*(self: SurrealDb, rows: seq[JsonNode], key="id"):Future[seq[string]] {.async.} =
  let sql = self.insertValuesBuilder(rows)
  let resp = getAllRows(self, sql, self.placeHolder).await
  return resp.map(
    proc(row:JsonNode):string =
      return row[key].getStr()
  )

# ==================== RawQuery ====================
proc get*(self: RawQuerySurrealDb):Future[seq[JsonNode]]{.async.} =
  ## It is only used with raw()
  try:
    self.log.logger(self.queryString, self.placeHolder)
    return getAllRows(self, self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode]()


proc first*(self: RawQuerySurrealDb):Future[Option[JsonNode]] {.async.} =
  # defer: self.cleanUp()
  try:
    self.log.logger(self.queryString, self.placeHolder)
    return getRow(self, self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


proc exec*(self: RawQuerySurrealDb){.async.} =
  ## It is only used with raw()
  try:
    self.log.logger(self.queryString, self.placeHolder)
    self.conn.exec(self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
