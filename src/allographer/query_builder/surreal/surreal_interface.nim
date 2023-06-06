import std/asyncdispatch
import std/json
import std/options
import std/sequtils
import ../log
import ../enums
import ./surreal_types
import ./query/builder
import ./query/grammar
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
  ## https://surrealdb.com/docs/surrealql/statements/select
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getAllRows(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode]()


proc first*(self: SurrealDb):Future[Option[JsonNode]] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/select
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


proc find*(self: SurrealDb, id:SurrealId, key="id"):Future[Option[JsonNode]]{.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/select
  self.placeHolder.add(id.rawId)
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
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


proc insert*(self: SurrealDb, items: seq[JsonNode]){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValuesBuilder(items)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


proc insertId*(self: SurrealDb, items: JsonNode, key="id"):Future[SurrealId] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql, self.placeHolder)
  let res = getRow(self, sql, self.placeHolder).await
  if res.isSome():
    return SurrealId.new(res.get()[key].getStr())
  else:
    return SurrealId.new()


proc insertId*(self: SurrealDb, items: seq[JsonNode], key="id"):Future[seq[SurrealId]] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValuesBuilder(items)
  self.log.logger(sql, self.placeHolder)
  let resp = getAllRows(self, sql, self.placeHolder).await
  return resp.map(
    proc(row:JsonNode):SurrealId =
      return SurrealId.new(row[key].getStr())
  )


# ==================== UPDATE ====================

proc update*(self:SurrealDb, items:JsonNode) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/update
  var updatePlaceHolder: seq[string]
  for item in items.pairs:
    if item.val.kind == JInt:
      updatePlaceHolder.add($(item.val.getInt()))
    elif item.val.kind == JFloat:
      updatePlaceHolder.add($(item.val.getFloat()))
    elif item.val.kind == JBool:
      updatePlaceHolder.add($(item.val.getBool()))
    elif [JObject, JArray].contains(item.val.kind):
      updatePlaceHolder.add($(item.val))
    else:
      updatePlaceHolder.add(item.val.getStr())

  self.placeHolder = updatePlaceHolder & self.placeHolder
  let sql = self.updateBuilder(items)

  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


proc update*(self:SurrealDb, id:SurrealId, items:JsonNode) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/update
  let sql = self.updateMergeBuilder(id.rawid, items)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


# ==================== DELETE ====================

proc delete*(self: SurrealDb){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/delete
  let sql = self.deleteBuilder()
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


proc delete*(self: SurrealDb, id: SurrealId){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/delete
  let sql = self.deleteByIdBuilder(id.rawId)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(sql, self.placeHolder, self.isInTransaction, self.transactionConn).await


# ==================== RawQuery ====================

proc get*(self: RawQuerySurrealDb):Future[seq[JsonNode]]{.async.} =
  ## It is only used with raw()
  ## 
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  try:
    self.log.logger(self.queryString, self.placeHolder)
    return getAllRows(self, self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode]()


proc first*(self: RawQuerySurrealDb):Future[Option[JsonNode]] {.async.} =
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  try:
    self.log.logger(self.queryString, self.placeHolder)
    return getRow(self, self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


proc exec*(self: RawQuerySurrealDb){.async.} =
  ## It is only used with raw()
  ## 
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  try:
    self.log.logger(self.queryString, self.placeHolder)
    self.conn.exec(self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )


proc info*(self: RawQuerySurrealDb):Future[JsonNode] {.async.} =
  ## Get all response.
  ## 
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  try:
    self.log.logger(self.queryString, self.placeHolder)
    return self.conn.info(self.queryString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.queryString, self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )


# ==================== Aggregates ====================

proc count*(self:SurrealDb):Future[int]{.async.} =
  var sql = self.countBuilder()
  sql = sql & " GROUP BY total"
  self.log.logger(sql, self.placeHolder)
  let response =  self.getRow(sql, self.placeHolder).await
  if response.isSome:
    return response.get["total"].getInt()
  else:
    return 0


proc max*(self:SurrealDb, column:string, collaction:Collation=None):Future[int]{.async.} =
  ## = `ORDER BY {column} {collaction} DESC LIMIT 1`
  let self = self.orderBy(column, collaction, Desc).limit(1)
  let sql = self.selectFirstBuilder()
  self.log.logger(sql, self.placeHolder)
  let response =  self.getRow(sql, self.placeHolder).await
  if response.isSome:
    return response.get[column].getInt()
  else:
    return 0


proc min*(self:SurrealDb, column:string, collaction:Collation=None):Future[int]{.async.} =
  ## = `ORDER BY {column} {collaction} ASC LIMIT 1`
  let self = self.orderBy(column, collaction, Asc).limit(1)
  let sql = self.selectFirstBuilder()
  self.log.logger(sql, self.placeHolder)
  let response =  self.getRow(sql, self.placeHolder).await
  if response.isSome:
    return response.get[column].getInt()
  else:
    return 0
