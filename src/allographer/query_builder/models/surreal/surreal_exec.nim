import std/asyncdispatch
import std/deques
import std/json
import std/monotimes
import std/options
import std/sequtils
import std/strformat
import std/strutils
import std/tables
import std/times
import ../../error
import ../../libs/surreal/surreal_lib
import ../../libs/surreal/surreal_impl
import ../../log
import ../../enums
import ../database_types
import ../../prepared_param
import ./query/surreal_builder
import ./surreal_types
import ./surreal_query


# ================================================================================
# connection
# ================================================================================

proc removePoolWaiter(pools: Connections, w: Future[void]) =
  var kept = initDeque[Future[void]]()
  while pools.waiters.len > 0:
    let x = pools.waiters.popFirst()
    if x != w:
      kept.addLast(x)
  pools.waiters = move(kept)

proc wakeOnePoolWaiter(pools: Connections) =
  while pools.waiters.len > 0:
    let w = pools.waiters.popFirst()
    if w.finished:
      continue
    w.complete()
    break

proc surrealPoolRemainingMs(deadline: MonoTime): int =
  let left = (deadline - getMonoTime()).inMilliseconds
  if left <= 0:
    return 0
  if left > int64(high(int)):
    return high(int)
  result = int(left)
  if result < 1:
    result = 1

proc getFreeConn(self: SurrealConnections | SurrealQuery | RawSurrealQuery): Future[int] {.async.} =
  let deadline = getMonoTime() + initDuration(seconds = self.pools.timeout)
  while true:
    for i in 0 ..< self.pools.conns.len:
      if not self.pools.conns[i].isBusy:
        self.pools.conns[i].isBusy = true
        when defined(check_pool):
          echo "=== getFreeConn ", i
        return i
    if getMonoTime() >= deadline:
      return errorConnectionNum
    let w = newFuture[void]("getFreeConn.poolWait")
    self.pools.waiters.addLast(w)
    var ms = surrealPoolRemainingMs(deadline)
    if ms < 1:
      ms = 1
    let ok = await withTimeout(w, ms)
    if not ok:
      removePoolWaiter(self.pools, w)
      return errorConnectionNum


proc returnConn(self: SurrealConnections | SurrealQuery | RawSurrealQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false
    wakeOnePoolWaiter(self.pools)


proc raisePoolTimeout(self: SurrealConnections | SurrealQuery | RawSurrealQuery | SurrealPreparedStatement) {.noreturn.} =
  raise newException(DbError, "Timed out while waiting for a free SurrealDB connection")


proc touchStmtEntry(entry: SurrealPreparedEntry) =
  entry.lastUsedAt = getTime().toUnix()


proc mustBeOpen(self: SurrealPreparedStatement) =
  if self.isNil or self.owner.isNil or self.isClosed:
    raise newException(DbError, "SurrealDB prepared statement is already closed")


proc hasPreparedEntry(cache: Table[string, SurrealPreparedEntry], sql: string): bool =
  for key in cache.keys:
    if key == sql:
      return true
  return false


proc getStmtEntry(self: SurrealConnections, sql: string): SurrealPreparedEntry =
  if hasPreparedEntry(self.pools.preparedCache, sql):
    return self.pools.preparedCache[sql]
  let entry = SurrealPreparedEntry(
    sql: sql,
    normalizedSql: sql.questionToDaller(),
    nArgs: countQuestionMarks(sql),
    refCount: 0,
    lastUsedAt: getTime().toUnix(),
  )
  self.pools.preparedCache[sql] = entry
  return entry


proc prepare*(self: SurrealConnections, sql: string): SurrealPreparedStatement =
  let entry = self.getStmtEntry(sql)
  entry.refCount += 1
  touchStmtEntry(entry)
  new(result)
  result.owner = self
  result.entry = entry
  result.sql = sql
  result.nArgs = entry.nArgs
  result.isClosed = false


proc withConn*(
  self: SurrealConnections,
  body: proc (ctx: SurrealPreparedContext): Future[void]
) {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  defer:
    self.returnConn(connI).await

  let ctx = SurrealPreparedContext(owner: self, connI: connI)
  await body(ctx)


proc verifyCtx(self: SurrealPreparedStatement, ctx: SurrealPreparedContext) =
  self.mustBeOpen()
  if ctx.isNil:
    raise newException(DbError, "SurrealDB prepared context is nil")
  if ctx.owner.isNil or ctx.owner != self.owner:
    raise newException(DbError, "SurrealDB prepared context owner mismatch")
  if ctx.connI < 0 or ctx.connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SurrealDB prepared context has invalid connection index")


proc toPreparedArgsJson(args: seq[string]): JsonNode =
  result = newJArray()
  for arg in args:
    if arg == "NULL" or arg == "null":
      result.add(newJNull())
    else:
      result.add(%arg)


proc buildPreparedSql(self: SurrealPreparedStatement, args: JsonNode): string =
  self.mustBeOpen()
  touchStmtEntry(self.entry)
  result = dbFormatPrepared(self.entry.normalizedSql, args)


proc getPreparedRowsOnConn(
  self: SurrealPreparedStatement,
  connI: int,
  args: JsonNode
): Future[seq[JsonNode]] {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SurrealDB prepared statement received an invalid connection index")

  let sql = self.buildPreparedSql(args)
  let rows = surreal_impl.query(
    self.owner.pools.conns[connI].conn,
    sql,
    newJArray(),
    self.owner.pools.timeout
  ).await

  if rows.kind != JArray or rows.len == 0:
    return newSeq[JsonNode](0)
  return rows.getElems()


proc getPreparedRowOnConn(
  self: SurrealPreparedStatement,
  connI: int,
  args: JsonNode
): Future[Option[JsonNode]] {.async.} =
  let rows = await self.getPreparedRowsOnConn(connI, args)
  if rows.len == 0:
    return none(JsonNode)
  return rows[0].some


proc execPreparedOnConn(
  self: SurrealPreparedStatement,
  connI: int,
  args: JsonNode
) {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SurrealDB prepared statement received an invalid connection index")

  let sql = self.buildPreparedSql(args)
  await surreal_impl.exec(
    self.owner.pools.conns[connI].conn,
    sql,
    newJArray(),
    self.owner.pools.timeout
  )


proc getPreparedRows(self: SurrealPreparedStatement, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  let connI = await getFreeConn(self.owner)
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  defer:
    await self.owner.returnConn(connI)
  return await self.getPreparedRowsOnConn(connI, args)


proc getPreparedRows(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  self.verifyCtx(ctx)
  return await self.getPreparedRowsOnConn(ctx.connI, args)


proc getPreparedRow(self: SurrealPreparedStatement, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  let rows = await self.getPreparedRows(args)
  if rows.len == 0:
    return none(JsonNode)
  return rows[0].some


proc getPreparedRow(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  self.verifyCtx(ctx)
  return await self.getPreparedRowOnConn(ctx.connI, args)


proc execPrepared(self: SurrealPreparedStatement, args: JsonNode) {.async.} =
  let connI = await getFreeConn(self.owner)
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  defer:
    await self.owner.returnConn(connI)
  await self.execPreparedOnConn(connI, args)


proc execPrepared(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: JsonNode) {.async.} =
  self.verifyCtx(ctx)
  await self.execPreparedOnConn(ctx.connI, args)


# ================================================================================
# toJson
# ================================================================================

# proc toJson(results:openArray[seq[string]], dbRows:DbRows):seq[JsonNode] =
#   var response_table = newSeq[JsonNode](results.len)
#   for index, rows in results.pairs:
#     var response_row = newJObject()
#     for i, row in rows:
#       let key = dbRows[index][i].name
#       let typ = dbRows[index][i].typ.kind
#       # let kindName = dbRows[index][i].typ.name
#       # let size = dbRows[index][i].typ.size

#       if typ == dbNull:
#         response_row[key] = newJNull()
#       elif [dbInt, dbUInt].contains(typ):
#         response_row[key] = newJInt(row.parseInt)
#       elif [dbDecimal, dbFloat].contains(typ):
#         response_row[key] = newJFloat(row.parseFloat)
#       elif [dbBool].contains(typ):
#         if row == "f":
#           response_row[key] = newJBool(false)
#         elif row == "t":
#           response_row[key] = newJBool(true)
#       elif [dbJson].contains(typ):
#         response_row[key] = row.parseJson
#       elif [dbFixedChar, dbVarchar].contains(typ):
#         if row == "NULL":
#           response_row[key] = newJNull()
#         else:
#           response_row[key] = newJString(row)
#       else:
#         response_row[key] = newJString(row)
    
#     response_table[index] = response_row
#   return response_table


# ================================================================================
# private exec
# ================================================================================

proc getAllRows(self:SurrealQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let rows = surreal_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return rows.getElems() # seq[JsonNode]


proc getRow(self:SurrealQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let rows = surreal_impl.query(self.pools.conns[connI].conn, queryString, self.placeHolder, self.pools.timeout).await
  if rows.len == 0:
    return none(JsonNode)
  else:
    return rows[0].some


proc exec(self:SurrealQuery, queryString:string) {.async.} =
  ## args is `JObject`
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  surreal_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, self.pools.timeout).await


# proc insertId(self:SurrealQuery, queryString:string, key:string):Future[string] {.async.} =
#   var connI = self.transactionConn
#   if not self.isInTransaction:
#     connI = getFreeConn(self).await
#   defer:
#     if not self.isInTransaction:
#       self.returnConn(connI).await
#   if connI == errorConnectionNum:
#     return

#   let table = self.query["table"].getStr
#   let columnGetQuery = &"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'"
#   let (columns, _) = surreal_impl.query(self.pools.conns[connI].conn, columnGetQuery, newJArray(), self.pools.timeout).await

#   let (rows, _) = surreal_impl.execGetValue(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await
#   return rows[0][0]


proc getAllRows(self:RawSurrealQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let rows = surreal_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return rows.getElems()


# proc getAllRowsPlain(self:RawSurrealQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
#   var connI = self.transactionConn
#   if not self.isInTransaction:
#     connI = getFreeConn(self).await
#   defer:
#     if not self.isInTransaction:
#       self.returnConn(connI).await
#   if connI == errorConnectionNum:
#     return

#   let queryString = queryString.questionToDaller()

#   let (rows, _) = surreal_impl.rawQuery(
#     self.pools.conns[connI].conn,
#     queryString,
#     self.placeHolder,
#     self.pools.timeout
#   ).await
  
#   return rows


proc getRow(self:RawSurrealQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let rows = surreal_impl.query(self.pools.conns[connI].conn, queryString, self.placeHolder, self.pools.timeout).await
  if rows.len == 0:
    return none(JsonNode)
  else:
    return rows[^1].some


# proc getRowPlain(self:RawSurrealQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
#   var connI = self.transactionConn
#   if not self.isInTransaction:
#     connI = getFreeConn(self).await
#   defer:
#     if not self.isInTransaction:
#       self.returnConn(connI).await
#   if connI == errorConnectionNum:
#     return

#   let queryString = queryString.questionToDaller()
  
#   let (rows, _) = surreal_impl.rawQuery(
#     self.pools.conns[connI].conn,
#     queryString,
#     self.placeHolder,
#     self.pools.timeout
#   ).await
#   return rows[0]


proc exec(self:RawSurrealQuery, queryString:string) {.async.} =
  let connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  surreal_impl.exec(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await


proc info(self:RawSurrealQuery, queryString:string):Future[JsonNode] {.async.} =
  let connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  return surreal_impl.info(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await


proc column(self:SurrealQuery, queryString:string):Future[JsonNode] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  var strArgs:seq[string]
  for arg in self.placeHolder.items:
    case arg["value"].kind
    of JBool:
      if arg["value"].getBool:
        strArgs.add("1")
      else:
        strArgs.add("0")
    of JInt:
      strArgs.add($arg["value"].getInt)
    of JFloat:
      strArgs.add($arg["value"].getFloat)
    of JString:
      strArgs.add($arg["value"].getStr)
    of JNull:
      strArgs.add("NULL")
    else:
      strArgs.add(arg["value"].pretty)

  return surreal_impl.info(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await


# ================================================================================
# prepared statement cache
# ================================================================================

proc close*(self: SurrealPreparedStatement) {.async.} =
  if self.isNil or self.isClosed:
    return
  self.isClosed = true
  if not self.entry.isNil and self.entry.refCount > 0:
    self.entry.refCount -= 1
    touchStmtEntry(self.entry)


proc removePreparedEntry(self: SurrealConnections, sql: string) =
  if not self.pools.preparedCache.hasKey(sql):
    return
  self.pools.preparedCache.del(sql)


proc flushStmt*(self: SurrealConnections, stmt: SurrealPreparedStatement) {.async.} =
  if stmt.isNil:
    return
  let sql = stmt.sql
  await stmt.close()
  self.removePreparedEntry(sql)


proc clearStmtCache*(self: SurrealConnections) {.async.} =
  let keys = toSeq(self.pools.preparedCache.keys)
  for sql in keys:
    self.removePreparedEntry(sql)


# ================================================================================
# public prepared exec
# ================================================================================

proc get*(self: SurrealPreparedStatement, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRows(toPreparedArgsJson(args))
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc get*(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRows(ctx, toPreparedArgsJson(args))
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc get*(self: SurrealPreparedStatement, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRows(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc get*(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRows(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc first*(self: SurrealPreparedStatement, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(toPreparedArgsJson(args))
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc first*(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(ctx, toPreparedArgsJson(args))
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc first*(self: SurrealPreparedStatement, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc first*(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc exec*(self: SurrealPreparedStatement, args: seq[string]) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(toPreparedArgsJson(args))
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc exec*(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: seq[string]) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(ctx, toPreparedArgsJson(args))
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc exec*(self: SurrealPreparedStatement, args: JsonNode) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc exec*(self: SurrealPreparedStatement, ctx: SurrealPreparedContext, args: JsonNode) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


# proc transactionStart(self:SurrealConnections) {.async.} =
#   let connI = getFreeConn(self).await
#   if connI == errorConnectionNum:
#     return
#   self.isInTransaction = true
#   self.transactionConn = connI

#   surreal_impl.exec(self.pools.conns[connI].conn, "BEGIN", newJArray(), newSeq[Row](), self.pools.timeout).await


# proc transactionEnd(self:SurrealConnections, query:string) {.async.} =
#   defer:
#     self.returnConn(self.transactionConn).await
#     self.transactionConn = 0
#     self.isInTransaction = false

#   surreal_impl.exec(self.pools[self.transactionConn].conn, query, newJArray(), newSeq[Row](), self.pools.timeout).await


# ================================================================================
# public exec
# ================================================================================

proc get*(self: SurrealQuery):Future[seq[JsonNode]] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/select
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode]()


proc first*(self: SurrealQuery):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


proc find*(self: SurrealQuery, id:SurrealId, key="id"):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFindBuilder(id, key)
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


# ==================== insert JsonNode ====================
proc insert*(self:SurrealQuery, items:JsonNode) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*(self:SurrealQuery, items:seq[JsonNode]) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  var sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*(self:SurrealQuery, items:JsonNode, key="id"):Future[SurrealId] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  var sql = self.insertValueBuilder(items) & " RETURN AFTER"
  self.log.logger(sql)
  let res = self.getRow(sql).await
  return SurrealId.new(res.get()[key].getStr)


proc insertId*(self: SurrealQuery, items: seq[JsonNode], key="id"):Future[seq[SurrealId]] {.async.} =
  result = newSeq[SurrealId](items.len)
  var sql = self.insertValuesBuilder(items) & " RETURN AFTER"
  self.log.logger(sql)
  let res = self.getAllRows(sql).await
  var i = 0
  for row in res.items:
    defer: i.inc()
    result[i] = SurrealId.new(row[key].getStr)


# ==================== insert Object ====================
proc insert*[T](self:SurrealQuery, items:T) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValueBuilder(%items)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*[T](self:SurrealQuery, items:seq[T]) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  var jsonItems = newSeq[JsonNode](items.len)
  for i, item in items:
    jsonItems[i] = %item
  var sql = self.insertValuesBuilder(jsonItems)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*[T](self:SurrealQuery, items:T, key="id"):Future[SurrealId] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  var sql = self.insertValueBuilder(%items) & " RETURN AFTER"
  self.log.logger(sql)
  let res = self.getRow(sql).await
  return SurrealId.new(res.get()[key].getStr)


proc insertId*[T](self: SurrealQuery, items: seq[T], key="id"):Future[seq[SurrealId]] {.async.} =
  result = newSeq[SurrealId](items.len)
  var jsonItems = newSeq[JsonNode](items.len)
  for i, item in items:
    jsonItems[i] = %item
  var sql = self.insertValuesBuilder(jsonItems) & " RETURN AFTER"
  self.log.logger(sql)
  let res = self.getAllRows(sql).await
  var i = 0
  for row in res.items:
    defer: i.inc()
    result[i] = SurrealId.new(row[key].getStr)


proc update*(self: SurrealQuery, items: JsonNode){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/update
  var sql = self.updateBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc update*(self:SurrealConnections, id:SurrealId, items:JsonNode) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/update
  let surrealQuery = SurrealQuery.new(
    self.log,
    self.pools,
    newJObject()
  )
  let sql = surrealQuery.updateMergeBuilder(id.rawid, items)
  surrealQuery.log.logger(sql)
  surrealQuery.exec(sql).await


proc update*[T](self: SurrealQuery, items: T){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/update
  var sql = self.updateBuilder(%items)
  self.log.logger(sql)
  self.exec(sql).await


proc update*[T](self:SurrealConnections, id:SurrealId, items:T) {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/update
  let surrealQuery = SurrealQuery.new(
    self.log,
    self.pools,
    newJObject()
  )
  let sql = surrealQuery.updateMergeBuilder(id.rawid, %items)
  surrealQuery.log.logger(sql)
  surrealQuery.exec(sql).await


proc delete*(self: SurrealQuery){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/delete
  let sql = self.deleteBuilder()
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self: SurrealQuery, id: SurrealId){.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/delete
  let sql = self.deleteByIdBuilder(id.rawId)
  self.log.logger(sql)
  self.exec(sql).await


proc columns*(self: SurrealQuery):Future[seq[string]] {.async.} =
  let tableName = self.query["table"].getStr
  let sql = &"INFO FOR TABLE `{tableName}`"
  try:
    self.log.logger(sql)
    let resp = self.column(sql).await
    var columns:seq[string]
    for (key, value) in resp[0]["result"]["fields"].pairs:
      columns.add(key)
    return columns
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return @[]


proc count*(self:SurrealQuery):Future[int] {.async.} =
  let sql = self.countBuilder()
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome:
    return response.get["total"].getInt()
  else:
    return 0


proc min*(self:SurrealQuery, column:string, collaction:Collation=None):Future[string] {.async.} =
  ## = `ORDER BY {column} {collaction} ASC LIMIT 1`
  let self = self.orderBy(column, collaction, Asc).limit(1)
  let sql = self.selectFirstBuilder()
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome():
    let column = if column.contains("."): column.split(".")[^1] else: column
    let value = response.get()[column]
    case value.kind
    of JString:
      return $value.getStr()
    else:
      return $value
  else:
    return ""


proc max*(self:SurrealQuery, column:string, collaction:Collation=None):Future[string]{.async.} =
  ## = `ORDER BY {column} {collaction} DESC LIMIT 1`
  let self = self.orderBy(column, collaction, Desc).limit(1)
  let sql = self.selectFirstBuilder()
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome():
    let column = if column.contains("."): column.split(".")[^1] else: column
    let value = response.get()[column]
    case value.kind
    of JString:
      return $value.getStr()
    else:
      return $value
  else:
    return ""


proc avg*(self:SurrealQuery, column:string):Future[float]{.async.} =
  var sql = self.selectAvgBuilder(column)
  self.log.logger(sql)
  let response =  await self.getRow(sql)
  if response.isSome:
    let value = response.get["avg"]
    case value.kind
    of JInt:
      return value.getInt.float
    of JFloat:
      return value.getFloat()
    of JString:
      return value.getStr().parseFloat()
    else:
      return 0.0
  else:
    return 0.0


proc sum*(self:SurrealQuery, column:string):Future[float]{.async.} =
  var sql = self.selectSumBuilder(column)
  self.log.logger(sql)
  let response =  await self.getRow(sql)
  if response.isSome:
    return response.get["sum"].getFloat()
  else:
    return 0.0


proc get*(self: RawSurrealQuery):Future[seq[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRows(self.queryString).await


proc exec*(self: RawSurrealQuery) {.async.} =
  ## It is only used with raw()
  ## 
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  try:
    self.log.logger(self.queryString)
    self.exec(self.queryString).await
  except CatchableError:
    self.log.echoErrorMsg(self.queryString)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )


proc info*(self: RawSurrealQuery):Future[JsonNode] {.async.} =
  ## Get all response.
  ## 
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  try:
    self.log.logger(self.queryString)
    return self.info(self.queryString).await
  except CatchableError:
    self.log.echoErrorMsg(self.queryString)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )


proc first*(self: RawSurrealQuery):Future[Option[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRow(self.queryString).await


template seeder*(rdb:SurrealConnections, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table is empty.
  block:
    if rdb.table(tableName).count().waitFor == 0:
      body


template seeder*(rdb:SurrealConnections, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  block:
    if rdb.table(tableName).select(column).count().waitFor == 0:
      body
