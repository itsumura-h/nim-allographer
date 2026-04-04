import std/asyncdispatch
import std/deques
import std/json
import std/monotimes
import std/options
import std/strutils
import std/sequtils
import std/tables
import std/times
import ../../error
import ../../libs/sqlite/sqlite_impl
import ../../libs/sqlite/sqlite_lib
import ../../libs/sqlite/sqlite_rdb
import ../../log
import ../database_types
import ../../prepared_param
import ./query/sqlite_builder
import ./sqlite_types


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

proc poolRemainingMs(deadline: MonoTime): int =
  let left = (deadline - getMonoTime()).inMilliseconds
  if left <= 0:
    return 0
  if left > int64(high(int)):
    return high(int)
  result = int(left)
  if result < 1:
    result = 1


proc nowUnix(): int64 =
  getTime().toUnix()


proc hasConnExpired(self: Connections, conn: Connection): bool =
  let now = nowUnix()
  if self.maxConnectionLifetime > 0 and now - conn.createdAt >= self.maxConnectionLifetime.int64:
    return true
  if self.maxConnectionIdleTime > 0 and now - conn.lastUsedAt >= self.maxConnectionIdleTime.int64:
    return true
  return false


proc openSqliteConn(self: Connections): PSqlite3 =
  var db: PSqlite3
  discard sqlite_rdb.open(self.database.cstring, db)
  if db.isNil:
    raise newException(DbError, "SQLite connection could not be opened")
  return db


proc clearPreparedSlot(self: Connections, connI: int) =
  for entry in self.preparedCache.values:
    if connI < 0 or connI >= entry.stmts.len:
      continue
    if not entry.stmts[connI].isNil:
      discard finalize(entry.stmts[connI])
      entry.stmts[connI] = nil


proc refreshConn(self: Connections, connI: int): bool =
  if connI < 0 or connI >= self.conns.len:
    return false
  let db = openSqliteConn(self)
  let oldConn = self.conns[connI].conn
  self.clearPreparedSlot(connI)
  if not oldConn.isNil:
    discard sqlite_rdb.close(oldConn)
  self.conns[connI].conn = db
  self.conns[connI].createdAt = nowUnix()
  self.conns[connI].lastUsedAt = self.conns[connI].createdAt
  return true

proc getFreeConn(self: SqliteConnections | SqliteQuery | RawSqliteQuery): Future[int] {.async.} =
  let deadline = getMonoTime() + initDuration(seconds = self.pools.timeout)
  while true:
    for i in 0 ..< self.pools.conns.len:
      if not self.pools.conns[i].isBusy:
        self.pools.conns[i].isBusy = true
        if self.pools.hasConnExpired(self.pools.conns[i]):
          try:
            discard self.pools.refreshConn(i)
          except CatchableError:
            discard
        when defined(check_pool):
          echo "=== getFreeConn ", i
        return i
    if getMonoTime() >= deadline:
      return errorConnectionNum
    let w = newFuture[void]("getFreeConn.poolWait")
    self.pools.waiters.addLast(w)
    var ms = poolRemainingMs(deadline)
    if ms < 1:
      ms = 1
    let ok = await withTimeout(w, ms)
    if not ok:
      removePoolWaiter(self.pools, w)
      return errorConnectionNum


proc returnConn(self: SqliteConnections | SqliteQuery | RawSqliteQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false
    self.pools.conns[i].lastUsedAt = nowUnix()
    wakeOnePoolWaiter(self.pools)


proc raisePoolTimeout(self: SqliteConnections | SqliteQuery | RawSqliteQuery | SqlitePreparedStatement) {.noreturn.} =
  raise newException(DbError, "Timed out while waiting for a free SQLite connection")


proc touchStmtEntry(entry: SqlitePreparedEntry) =
  entry.lastUsedAt = getTime().toUnix()


proc mustBeOpen(self: SqlitePreparedStatement) =
  if self.isNil or self.isClosed:
    raise newException(DbError, "SQLite prepared statement is already closed")


proc hasPreparedEntry(cache: Table[string, SqlitePreparedEntry], sql: string): bool =
  for key in cache.keys:
    if key == sql:
      return true
  return false


proc getStmtEntry(self: SqliteConnections, sql: string): SqlitePreparedEntry =
  if hasPreparedEntry(self.pools.preparedCache, sql):
    return self.pools.preparedCache[sql]
  let entry = SqlitePreparedEntry(
    sql: sql,
    nArgs: countQuestionMarks(sql),
    stmts: newSeq[PStmt](self.pools.conns.len),
    refCount: 0,
    lastUsedAt: getTime().toUnix(),
  )
  self.pools.preparedCache[sql] = entry
  return entry


proc prepare*(self: SqliteConnections, sql: string): SqlitePreparedStatement =
  new(result)
  result.owner = self
  result.entry = self.getStmtEntry(sql)
  result.sql = sql
  result.entry.refCount += 1
  touchStmtEntry(result.entry)


proc ensurePreparedStmt(self: SqlitePreparedStatement, connI: int): Future[PStmt] {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SQLite prepared statement received an invalid connection index")
  if self.entry.stmts[connI].isNil:
    self.entry.stmts[connI] = sqlite_impl.prepare(
      self.owner.pools.conns[connI].conn,
      self.sql,
      self.owner.pools.timeout
    ).await
  touchStmtEntry(self.entry)
  return self.entry.stmts[connI]


proc withConn*(
  self: SqliteConnections,
  body: proc (ctx: SqlitePreparedContext): Future[void]
) {.async.} =
  if self.isInTransaction:
    let ctx = SqlitePreparedContext(owner: self, connI: self.transactionConn)
    await body(ctx)
    return

  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  defer:
    self.returnConn(connI).await

  let ctx = SqlitePreparedContext(owner: self, connI: connI)
  await body(ctx)


proc verifyCtx(self: SqlitePreparedStatement, ctx: SqlitePreparedContext) =
  self.mustBeOpen()
  if ctx.isNil:
    raise newException(DbError, "SQLite prepared context is nil")
  if ctx.owner != self.owner:
    raise newException(DbError, "SQLite prepared context owner mismatch")
  if ctx.connI < 0 or ctx.connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SQLite prepared context has invalid connection index")



# ================================================================================
# toJson
# ================================================================================

proc toJson(results:openArray[seq[string]], dbRows:DbRows):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  for index, rows in results.pairs:
    var response_row = newJObject()
    for i, row in rows:
      let key = dbRows[index][i].name
      let typ = dbRows[index][i].typ.kind
      let kindName = dbRows[index][i].typ.name
      # let size = dbRows[index][i].typ.size

      if typ == dbNull:
        response_row[key] = newJNull()
      elif ["INTEGER", "INT", "SMALLINT", "MEDIUMINT", "BIGINT"].contains(kindName):
        response_row[key] = newJInt(row.parseInt)
      elif ["NUMERIC", "DECIMAL", "DOUBLE", "REAL"].contains(kindName):
        response_row[key] = newJFloat(row.parseFloat)
      elif ["TINYINT", "BOOLEAN"].contains(kindName):
        response_row[key] = newJBool(row.parseBool)
      else:
        response_row[key] = newJString(row)
      
    response_table[index] = response_row
  return response_table


# ================================================================================
# private exec
# ================================================================================

proc getCachedSqliteColumnTypes(self: SqliteQuery, connI: int): Future[seq[(string, string)]] {.async.} =
  let table = self.query["table"].getStr
  if self.pools.columnTypeCache.hasKey(table):
    return self.pools.columnTypeCache[table]
  let q = "PRAGMA table_info(" & sqliteQuoteIdent(table) & ")"
  let columns = sqlite_impl.getColumnTypes(self.pools.conns[connI].conn, q).await
  self.pools.columnTypeCache[table] = columns
  return columns


proc getAllRows(self:SqliteQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

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

  let (rows, dbRows) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]


proc getAllRowsPlain(self:SqliteQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in args.items:
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

  let (rows, _) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await
  return rows


proc getRow(self:SqliteQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

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

  let (rows, dbRows) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some() # Option[JsonNode]


proc getRowPlain(self:SqliteQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in args.items:
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
  let (rows, _) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await
  return rows[0]


proc getAllRows(self:RawSqliteQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in self.placeHolder.items:
    case arg.kind
    of JBool:
      if arg.getBool:
        strArgs.add("1")
      else:
        strArgs.add("0")
    of JInt:
      strArgs.add($arg.getInt)
    of JFloat:
      strArgs.add($arg.getFloat)
    of JString:
      strArgs.add($arg.getStr)
    of JNull:
      strArgs.add("NULL")
    else:
      strArgs.add(arg.pretty)

  let (rows, dbRows) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]


proc getAllRowsPlain(self:RawSqliteQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in args.items:
    case arg.kind
    of JBool:
      if arg.getBool:
        strArgs.add("1")
      else:
        strArgs.add("0")
    of JInt:
      strArgs.add($arg.getInt)
    of JFloat:
      strArgs.add($arg.getFloat)
    of JString:
      strArgs.add($arg.getStr)
    of JNull:
      strArgs.add("NULL")
    else:
      strArgs.add(arg.pretty)

  let (rows, _) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await
  return rows


proc getRow(self:RawSqliteQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in self.placeHolder.items:
    case arg.kind
    of JBool:
      if arg.getBool:
        strArgs.add("1")
      else:
        strArgs.add("0")
    of JInt:
      strArgs.add($arg.getInt)
    of JFloat:
      strArgs.add($arg.getFloat)
    of JString:
      strArgs.add($arg.getStr)
    of JNull:
      strArgs.add("NULL")
    else:
      strArgs.add(arg.pretty)
  
  let (rows, dbRows) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some


proc getRowPlain(self:RawSqliteQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in args.items:
    case arg.kind
    of JBool:
      if arg.getBool:
        strArgs.add("1")
      else:
        strArgs.add("0")
    of JInt:
      strArgs.add($arg.getInt)
    of JFloat:
      strArgs.add($arg.getFloat)
    of JString:
      strArgs.add($arg.getStr)
    of JNull:
      strArgs.add("NULL")
    else:
      strArgs.add(arg.pretty)
  
  let (rows, _) = sqlite_impl.query(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await
  return rows[0]


proc exec(self:SqliteQuery, queryString:string) {.async.} =
  ## args is `self.placeholder`
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let columns = getCachedSqliteColumnTypes(self, connI).await
  sqlite_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await


proc exec(self:RawSqliteQuery, queryString:string, args:JsonNode) {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  sqlite_impl.exec(self.pools.conns[connI].conn, queryString, args, self.pools.timeout).await


proc insertId(self:SqliteQuery, queryString:string, key:string):Future[string]{.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let columns = getCachedSqliteColumnTypes(self, connI).await
  sqlite_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await

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

  let (rows, _) = sqlite_impl.query(self.pools.conns[connI].conn, "SELECT last_insert_rowid()", strArgs, self.pools.timeout).await
  return rows[0][0]


proc getColumns(self:SqliteQuery, queryString:string, args=newJArray()):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  var strArgs:seq[string]
  for arg in args.items:
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

  return sqlite_impl.getColumns(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await


proc transactionStart(self:SqliteConnections) {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  self.isInTransaction = true
  self.transactionConn = connI
  sqlite_impl.exec(self.pools.conns[connI].conn, "BEGIN", newJArray(), self.pools.timeout).await


proc transactionEnd(self:SqliteConnections, query:string) {.async.} =
  defer:
    self.returnConn(self.transactionConn).await
    self.transactionConn = 0
    self.isInTransaction = false

  sqlite_impl.exec(self.pools.conns[self.transactionConn].conn, query, newJArray(), self.pools.timeout).await


proc getPreparedRowsOnConn(
  self: SqlitePreparedStatement,
  connI: int,
  args: seq[PreparedParam]
): Future[(seq[seq[string]], DbRows)] {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SQLite prepared statement received an invalid connection index")

  let stmt = await self.ensurePreparedStmt(connI)
  if not self.hasCachedColumns:
    setColumnsStaticMeta(self.cachedColumns, stmt)
    self.hasCachedColumns = true

  return sqlite_impl.preparedQueryReuse(
    self.owner.pools.conns[connI].conn,
    stmt,
    args,
    self.owner.pools.timeout,
    self.cachedColumns
  ).await


proc getPreparedRows(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[(seq[seq[string]], DbRows)] {.async.} =
  var connI = self.owner.transactionConn
  if not self.owner.isInTransaction:
    connI = getFreeConn(self.owner).await
  defer:
    if not self.owner.isInTransaction:
      self.owner.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  return await self.getPreparedRowsOnConn(connI, args)


proc getPreparedRows(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[(seq[seq[string]], DbRows)] {.async.} =
  self.verifyCtx(ctx)
  return await self.getPreparedRowsOnConn(ctx.connI, args)


proc getPreparedAllRows(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[seq[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows)


proc getPreparedRow(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[Option[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some()


proc getPreparedAllRowsPlain(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[seq[seq[string]]] {.async.} =
  let (rows, _) = await self.getPreparedRows(args)
  return rows


proc getPreparedRowPlain(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[seq[string]] {.async.} =
  let (rows, _) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[string](0)
  return rows[0]


proc getPreparedAllRows(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[seq[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(ctx, args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows)


proc getPreparedRow(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[Option[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(ctx, args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some()


proc getPreparedAllRowsPlain(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[seq[seq[string]]] {.async.} =
  let (rows, _) = await self.getPreparedRows(ctx, args)
  return rows


proc getPreparedRowPlain(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[seq[string]] {.async.} =
  let (rows, _) = await self.getPreparedRows(ctx, args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[string](0)
  return rows[0]


proc execPreparedOnConn(
  self: SqlitePreparedStatement,
  connI: int,
  args: seq[PreparedParam]
) {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "SQLite prepared statement received an invalid connection index")

  let stmt = await self.ensurePreparedStmt(connI)
  await sqlite_impl.preparedExecReuse(
    self.owner.pools.conns[connI].conn,
    stmt,
    args,
    self.owner.pools.timeout
  )


proc execPrepared(self: SqlitePreparedStatement, args: seq[PreparedParam]) {.async.} =
  var connI = self.owner.transactionConn
  if not self.owner.isInTransaction:
    connI = getFreeConn(self.owner).await
  defer:
    if not self.owner.isInTransaction:
      self.owner.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  await self.execPreparedOnConn(connI, args)


proc execPrepared(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
) {.async.} =
  self.verifyCtx(ctx)
  await self.execPreparedOnConn(ctx.connI, args)


proc preparedGet(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRows(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirst(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedGetPlain(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[seq[seq[string]]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRowsPlain(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirstPlain(self: SqlitePreparedStatement, args: seq[PreparedParam]): Future[seq[string]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRowPlain(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedExec(self: SqlitePreparedStatement, args: seq[PreparedParam]) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedGet(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRows(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirst(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedGetPlain(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[seq[seq[string]]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRowsPlain(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirstPlain(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
): Future[seq[string]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRowPlain(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedExec(
  self: SqlitePreparedStatement,
  ctx: SqlitePreparedContext,
  args: seq[PreparedParam]
) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


# ================================================================================
# public exec
# ================================================================================

# ==================== return json ====================
proc get*(self:SqliteQuery):Future[seq[JsonNode]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc first*(self:SqliteQuery):Future[Option[JsonNode]] {.async.} =
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self:SqliteQuery, id: string, key="id"):Future[Option[JsonNode]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self:SqliteQuery, id:int, key="id"):Future[Option[JsonNode]]{.async.} =
  return self.find($id, key).await


# ==================== return string ====================
proc getPlain*(self:SqliteQuery):Future[seq[seq[string]]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRowsPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc firstPlain*(self:SqliteQuery):Future[seq[string]] {.async.} =
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:SqliteQuery, id: string, key="id"):Future[seq[string]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:SqliteQuery, id: int, key="id"):Future[seq[string]] {.async.} =
  return self.findPlain($id, key).await


# ==================== insert JsonNode ====================
proc insert*(self:SqliteQuery, items:JsonNode) {.async.} =
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*(self:SqliteQuery, items:seq[JsonNode]) {.async.} =
  let sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*(self: SqliteQuery, items: JsonNode, key="id"):Future[string] {.async.} =
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*(self: SqliteQuery, items: seq[JsonNode], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    let sql = self.insertValueBuilder(item)
    self.log.logger(sql)
    result[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()


# ==================== insert Object ====================
proc insert*[T](self:SqliteQuery, items:T) {.async.} =
  let sql = self.insertValueBuilder(%items)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*[T](self:SqliteQuery, items:seq[T]) {.async.} =
  let items = items.mapIt(%it)
  let sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*[T](self: SqliteQuery, items: T, key="id"):Future[string] {.async.} =
  let sql = self.insertValueBuilder(%items)
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*[T](self: SqliteQuery, items: seq[T], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    let sql = self.insertValueBuilder(%item)
    self.log.logger(sql)
    result[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()


# ==================== update ====================
proc update*(self:SqliteQuery, items:JsonNode) {.async.} =
  let sql = self.updateBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc update*[T](self:SqliteQuery, items:T) {.async.} =
  let sql = self.updateBuilder(%items)
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self:SqliteQuery) {.async.} =
  let sql = self.deleteBuilder()
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self:SqliteQuery, id:int, key="id") {.async.} =
  let sql = self.deleteByIdBuilder(id, key)
  self.log.logger(sql)
  self.placeHolder.add(%*{"key":key, "value":id})
  self.exec(sql).await


proc columns*(self:SqliteQuery):Future[seq[string]] {.async.} =
  let sql = self.columnBuilder()
  self.log.logger(sql)
  return self.getColumns(sql, self.placeHolder).await


proc count*(self:SqliteQuery):Future[int] {.async.} =
  let sql = self.countBuilder()
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome:
    return response.get["aggregate"].getStr().parseInt()
  else:
    return 0


proc min*(self:SqliteQuery, column:string):Future[Option[string]] {.async.} =
  let sql = self.minBuilder(column)
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome:
    case response.get["aggregate"].kind
    of JInt:
      return some($(response.get["aggregate"].getInt))
    of JFloat:
      return some($(response.get["aggregate"].getFloat))
    else:
      return some(response.get["aggregate"].getStr)
  else:
    return none(string)


proc max*(self:SqliteQuery, column:string):Future[Option[string]] {.async.} =
  let sql = self.maxBuilder(column)
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome:
    case response.get["aggregate"].kind
    of JInt:
      return some($(response.get["aggregate"].getInt))
    of JFloat:
      return some($(response.get["aggregate"].getFloat))
    else:
      return some(response.get["aggregate"].getStr)
  else:
    return none(string)


proc avg*(self:SqliteQuery, column:string):Future[Option[float]]{.async.} =
  let sql = self.avgBuilder(column)
  self.log.logger(sql)
  let response =  await self.getRow(sql)
  if response.isSome:
    return response.get["aggregate"].getStr().parseFloat.some
  else:
    return none(float)


proc sum*(self:SqliteQuery, column:string):Future[Option[float]]{.async.} =
  let sql = self.sumBuilder(column)
  self.log.logger(sql)
  let response = await self.getRow(sql)
  if response.isSome:
    return response.get["aggregate"].getStr.parseFloat.some
  else:
    return none(float)


proc begin*(self:SqliteConnections) {.async.} =
  self.log.logger("BEGIN")
  self.transactionStart().await


proc rollback*(self:SqliteConnections) {.async.} =
  self.log.logger("ROLLBACK")
  self.transactionEnd("ROLLBACK").await


proc commit*(self:SqliteConnections) {.async.} =
  self.log.logger("COMMIT")
  self.transactionEnd("COMMIT").await


proc get*(self: RawSqliteQuery):Future[seq[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRows(self.queryString).await


proc getPlain*(self: RawSqliteQuery):Future[seq[seq[string]]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRowsPlain(self.queryString, self.placeHolder).await


proc exec*(self: RawSqliteQuery) {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  self.exec(self.queryString, self.placeHolder).await


proc first*(self: RawSqliteQuery):Future[Option[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRow(self.queryString).await


proc firstPlain*(self: RawSqliteQuery):Future[seq[string]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRowPlain(self.queryString, self.placeHolder).await


proc close*(self: SqlitePreparedStatement) {.async.} =
  if self.isNil or self.isClosed:
    return
  self.isClosed = true
  if not self.entry.isNil:
    if self.entry.refCount > 0:
      self.entry.refCount -= 1
    touchStmtEntry(self.entry)


proc flushStmt*(self: SqliteConnections, sql: string) {.async.} =
  if not hasPreparedEntry(self.pools.preparedCache, sql):
    return
  let entry = self.pools.preparedCache[sql]
  for i, stmt in entry.stmts:
    if stmt.isNil:
      continue
    try:
      discard finalize(stmt)
    except CatchableError:
      self.log.echoErrorMsg("finalize failed for prepared stmt: " & getCurrentExceptionMsg())
    entry.stmts[i] = nil
  self.pools.preparedCache.del(sql)


proc clearStmtCache*(self: SqliteConnections) {.async.} =
  let keys = toSeq(self.pools.preparedCache.keys)
  for sql in keys:
    await self.flushStmt(sql)


# ================================================================================
# public prepared exec
# ================================================================================

proc get*(self: SqlitePreparedStatement, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(args.toPreparedParams)


proc get*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(ctx, args.toPreparedParams)


proc get*(self: SqlitePreparedStatement, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(args.toPreparedParams)


proc get*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(ctx, args.toPreparedParams)


proc first*(self: SqlitePreparedStatement, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(args.toPreparedParams)


proc first*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(ctx, args.toPreparedParams)


proc first*(self: SqlitePreparedStatement, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(args.toPreparedParams)


proc first*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(ctx, args.toPreparedParams)


proc getPlain*(self: SqlitePreparedStatement, args: seq[string]): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(args.toPreparedParams)


proc getPlain*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: seq[string]): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(ctx, args.toPreparedParams)


proc getPlain*(self: SqlitePreparedStatement, args: JsonNode): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(args.toPreparedParams)


proc getPlain*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: JsonNode): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(ctx, args.toPreparedParams)


proc firstPlain*(self: SqlitePreparedStatement, args: seq[string]): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(args.toPreparedParams)


proc firstPlain*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: seq[string]): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(ctx, args.toPreparedParams)


proc firstPlain*(self: SqlitePreparedStatement, args: JsonNode): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(args.toPreparedParams)


proc firstPlain*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: JsonNode): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(ctx, args.toPreparedParams)


proc exec*(self: SqlitePreparedStatement, args: seq[string]) {.async.} =
  await self.preparedExec(args.toPreparedParams)


proc exec*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: seq[string]) {.async.} =
  await self.preparedExec(ctx, args.toPreparedParams)


proc exec*(self: SqlitePreparedStatement, args: JsonNode) {.async.} =
  await self.preparedExec(args.toPreparedParams)


proc exec*(self: SqlitePreparedStatement, ctx: SqlitePreparedContext, args: JsonNode) {.async.} =
  await self.preparedExec(ctx, args.toPreparedParams)



template seeder*(rdb:SqliteConnections, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table is empty.
  block:
    if rdb.table(tableName).count().waitFor == 0:
      body


template seeder*(rdb:SqliteConnections, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  block:
    if rdb.select(column).table(tableName).count().waitFor == 0:
      body
