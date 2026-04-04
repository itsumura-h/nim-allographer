import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/sequtils
import std/tables
import std/times
import ../../error
import ../../libs/mysql/mysql_impl
import ../../libs/mysql/mysql_rdb except Option
import ../../log
import ../database_types
import ../../prepared_param
import ./query/mysql_builder
import ./mysql_types


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:MysqlConnections | MysqlQuery | RawMysqlQuery):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.conns.len:
      if not self.pools.conns[i].isBusy:
        self.pools.conns[i].isBusy = true
        if self.pools.hasConnExpired(self.pools.conns[i]):
          try:
            discard self.pools.refreshConn(i)
          except CatchableError:
            discard
        when defined(check_pool):
          echo "=== getFreeConn ",i
        return i
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.pools.timeout:
      return errorConnectionNum


proc returnConn(self:MysqlConnections | MysqlQuery | RawMysqlQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false
    self.pools.conns[i].lastUsedAt = getTime().toUnix()


proc raisePoolTimeout(self: MysqlConnections | MysqlQuery | RawMysqlQuery | MysqlPreparedStatement) {.noreturn.} =
  raise newException(DbError, "Timed out while waiting for a free MySQL connection")


proc touchStmtEntry(entry: MysqlPreparedEntry) =
  entry.lastUsedAt = getTime().toUnix()


proc mustBeOpen(self: MysqlPreparedStatement) =
  if self.isNil or self.isClosed:
    raise newException(DbError, "MySQL prepared statement is already closed")


proc hasPreparedEntry(cache: Table[string, MysqlPreparedEntry], sql: string): bool =
  for key in cache.keys:
    if key == sql:
      return true
  return false


proc getStmtEntry(self: MysqlConnections, sql: string): MysqlPreparedEntry =
  if hasPreparedEntry(self.pools.preparedCache, sql):
    return self.pools.preparedCache[sql]
  let entry = MysqlPreparedEntry(
    sql: sql,
    nArgs: countQuestionMarks(sql),
    stmts: newSeq[PSTMT](self.pools.conns.len),
    refCount: 0,
    lastUsedAt: getTime().toUnix(),
  )
  self.pools.preparedCache[sql] = entry
  return entry


proc nowUnix(): int64 =
  getTime().toUnix()


proc hasConnExpired(self: Connections, conn: Connection): bool =
  let now = nowUnix()
  if self.maxConnectionLifetime > 0 and now - conn.createdAt >= self.maxConnectionLifetime.int64:
    return true
  if self.maxConnectionIdleTime > 0 and now - conn.lastUsedAt >= self.maxConnectionIdleTime.int64:
    return true
  return false


proc openMysqlConn(self: Connections): PMySQL =
  let conn = mysql_rdb.init(nil)
  if conn == nil:
    mysql_rdb.close(conn)
    dbError("mysql_rdb.init() failed")
  if mysql_rdb.real_connect(
    conn,
    self.info.host.cstring,
    self.info.user.cstring,
    self.info.password.cstring,
    self.info.database.cstring,
    self.info.port.int32,
    nil,
    0
  ) == nil:
    let errmsg = $mysql_rdb.error(conn)
    mysql_rdb.close(conn)
    dbError(errmsg)
  return conn


proc clearPreparedSlot(self: Connections, connI: int) =
  for entry in self.preparedCache.values:
    if connI < 0 or connI >= entry.stmts.len:
      continue
    if not entry.stmts[connI].isNil:
      mysql_impl.closePreparedStmt(entry.stmts[connI])
      entry.stmts[connI] = nil


proc refreshConn(self: Connections, connI: int): bool =
  if connI < 0 or connI >= self.conns.len:
    return false
  let conn = openMysqlConn(self)
  let oldConn = self.conns[connI].conn
  self.clearPreparedSlot(connI)
  if not oldConn.isNil:
    mysql_rdb.close(oldConn)
  self.conns[connI].conn = conn
  self.conns[connI].createdAt = nowUnix()
  self.conns[connI].lastUsedAt = self.conns[connI].createdAt
  return true


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
      # let kindName = dbRows[index][i].typ.name
      let size = dbRows[index][i].typ.size

      if typ == dbNull:
        response_row[key] = newJNull()
      elif [dbInt, dbUInt].contains(typ) and size == 1:
        if row == "0":
          response_row[key] = newJBool(false)
        elif row == "1":
          response_row[key] = newJBool(true)
      elif [dbInt, dbUInt].contains(typ):
        response_row[key] = newJInt(row.parseInt)
      elif [dbDecimal, dbFloat].contains(typ):
        response_row[key] = newJFloat(row.parseFloat)
      elif [dbJson].contains(typ):
        response_row[key] = row.parseJson
      else:
        response_row[key] = newJString(row)
    
    response_table[index] = response_row
  return response_table


# ================================================================================
# private exec
# ================================================================================

proc getAllRows(self:MysqlQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, dbRows) = mysql_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]


proc getAllRowsPlain(self:MysqlQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, _) = mysql_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  
  return rows


proc getRow(self:MysqlQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, dbRows) = mysql_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some # seq[JsonNode]


proc getRowPlain(self:MysqlQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  
  let (rows, _) = mysql_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  return rows[0]


proc exec(self:MysqlQuery, queryString:string) {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let database = self.info.database
  let table = self.query["table"].getStr
  let columns = mysql_impl.getColumnTypes(self.pools.conns[connI].conn, $database, table, self.pools.timeout).await
  mysql_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await


proc insertId(self:MysqlQuery, queryString:string, key:string):Future[string] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let table = self.query["table"].getStr
  let columnGetQuery = &"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'"
  let (columns, _) = mysql_impl.query(self.pools.conns[connI].conn, columnGetQuery, newJArray(), self.pools.timeout).await

  # let (rows, _) = mysql_impl.execGetValue(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await
  # return rows[0][0]
  mysql_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await
  let (rows, _) = mysql_impl.query(self.pools.conns[connI].conn, "SELECT LAST_INSERT_ID()", self.placeHolder, self.pools.timeout).await
  return rows[0][0]


proc getAllRows(self:RawMysqlQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, dbRows) = mysql_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]


proc getAllRowsPlain(self:RawMysqlQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
  ## args is JArray [true, 1, 1.1, "str"]
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, _) = mysql_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  
  return rows


proc getRow(self:RawMysqlQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, dbRows) = mysql_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some # seq[JsonNode]


proc getRowPlain(self:RawMysqlQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  let (rows, _) = mysql_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  return rows[0]


proc exec(self:RawMysqlQuery, queryString:string) {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)

  mysql_impl.exec(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await


proc getColumns(self:MysqlQuery, queryString:string):Future[seq[string]] {.async.} =
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

  return mysql_impl.getColumns(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await


proc transactionStart(self:MysqlConnections) {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  self.isInTransaction = true
  self.transactionConn = connI

  mysql_impl.exec(self.pools.conns[connI].conn, "BEGIN", newJArray(), newSeq[seq[string]](), self.pools.timeout).await


proc transactionEnd(self:MysqlConnections, query:string) {.async.} =
  defer:
    self.returnConn(self.transactionConn).await
    self.transactionConn = 0
    self.isInTransaction = false

  mysql_impl.exec(self.pools.conns[self.transactionConn].conn, query, newJArray(), newSeq[seq[string]](), self.pools.timeout).await


# ================================================================================
# public exec
# ================================================================================

proc get*(self: MysqlQuery):Future[seq[JsonNode]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc first*(self: MysqlQuery):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self: MysqlQuery, id:string, key="id"):Future[Option[JsonNode]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value": id})
  var sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self: MysqlQuery, id:int, key="id"):Future[Option[JsonNode]] {.async.} =
  return self.find($id, key).await


proc getPlain*(self:MysqlQuery):Future[seq[seq[string]]] {.async.} =
  var sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRowsPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc firstPlain*(self:MysqlQuery):Future[seq[string]] {.async.} =
  var sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:MysqlQuery, id: string, key="id"):Future[seq[string]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  var sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:MysqlQuery, id: int, key="id"):Future[seq[string]] {.async.} =
  return self.findPlain($id, key).await


# ==================== intert JsonNode ====================
proc insert*(self:MysqlQuery, items:JsonNode) {.async.} =
  ## items is `JObject`
  var sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*(self:MysqlQuery, items:seq[JsonNode]) {.async.} =
  var sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*(self:MysqlQuery, items:JsonNode, key="id"):Future[string] {.async.} =
  var sql = self.insertValueBuilder(items)
  # sql.add(&" RETURNING `{key}`")
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*(self: MysqlQuery, items: seq[JsonNode], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    var sql = self.insertValueBuilder(item)
    # sql.add(&" RETURNING `{key}`")
    self.log.logger(sql)
    result[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()


# ==================== intert Object ====================
proc insert*[T](self:MysqlQuery, items:T) {.async.} =
  var sql = self.insertValueBuilder(%items)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*[T](self:MysqlQuery, items:seq[T]) {.async.} =
  let items = items.mapIt(%it)
  var sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*[T](self:MysqlQuery, items:T, key="id"):Future[string] {.async.} =
  var sql = self.insertValueBuilder(%items)
  # sql.add(&" RETURNING `{key}`")
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*[T](self: MysqlQuery, items: seq[T], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    var sql = self.insertValueBuilder(%item)
    # sql.add(&" RETURNING `{key}`")
    self.log.logger(sql)
    result[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()


proc update*(self: MysqlQuery, items: JsonNode){.async.} =
  var sql = self.updateBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc update*[T](self: MysqlQuery, items: T){.async.} =
  var sql = self.updateBuilder(%items)
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self: MysqlQuery){.async.} =
  var sql = self.deleteBuilder()
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self: MysqlQuery, id: int, key="id"){.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  var sql = self.deleteByIdBuilder(id, key)
  self.log.logger(sql)
  self.exec(sql).await


proc columns*(self:MysqlQuery):Future[seq[string]] {.async.} =
  ## get columns sequence from table
  var sql = self.columnBuilder()
  try:
    self.log.logger(sql)
    return self.getColumns(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc count*(self:MysqlQuery):Future[int] {.async.} =
  var sql = self.countBuilder()
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome:
    return response.get["aggregate"].getInt()
  else:
    return 0


proc min*(self:MysqlQuery, column:string):Future[Option[string]] {.async.} =
  var sql = self.minBuilder(column)
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


proc max*(self:MysqlQuery, column:string):Future[Option[string]] {.async.} =
  var sql = self.maxBuilder(column)
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


proc avg*(self:MysqlQuery, column:string):Future[Option[float]]{.async.} =
  var sql = self.avgBuilder(column)
  self.log.logger(sql)
  let response =  await self.getRow(sql)
  if response.isSome:
    return response.get["aggregate"].getFloat().some
  else:
    return none(float)


proc sum*(self:MysqlQuery, column:string):Future[Option[float]]{.async.} =
  var sql = self.sumBuilder(column)
  self.log.logger(sql)
  let response = await self.getRow(sql)
  if response.isSome:
    return response.get["aggregate"].getFloat().some
  else:
    return none(float)


proc begin*(self:MysqlConnections) {.async.} =
  self.log.logger("BEGIN")
  self.transactionStart().await


proc rollback*(self:MysqlConnections) {.async.} =
  self.log.logger("ROLLBACK")
  self.transactionEnd("ROLLBACK").await


proc commit*(self:MysqlConnections) {.async.} =
  self.log.logger("COMMIT")
  self.transactionEnd("COMMIT").await


proc withConn*(
  self: MysqlConnections,
  body: proc (ctx: MysqlPreparedContext): Future[void]
) {.async.} =
  if self.isInTransaction:
    let ctx = MysqlPreparedContext(owner: self, connI: self.transactionConn)
    await body(ctx)
    return

  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    raisePoolTimeout(self)
  defer:
    self.returnConn(connI).await

  let ctx = MysqlPreparedContext(owner: self, connI: connI)
  await body(ctx)


proc verifyCtx(self: MysqlPreparedStatement, ctx: MysqlPreparedContext) =
  self.mustBeOpen()
  if ctx.isNil:
    raise newException(DbError, "MySQL prepared context is nil")
  if ctx.owner != self.owner:
    raise newException(DbError, "MySQL prepared context owner mismatch")
  if ctx.connI < 0 or ctx.connI >= self.owner.pools.conns.len:
    raise newException(DbError, "MySQL prepared context has invalid connection index")


proc prepare*(self: MysqlConnections, sql: string): MysqlPreparedStatement =
  new(result)
  result.owner = self
  result.info = self.info
  result.entry = self.getStmtEntry(sql)
  result.sql = sql
  result.nArgs = result.entry.nArgs
  result.entry.refCount += 1
  touchStmtEntry(result.entry)
  result.resultBindCache = newSeq[MysqlResultBindCache](self.pools.conns.len)


proc ensurePreparedStmt(self: MysqlPreparedStatement, connI: int): Future[PSTMT] {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "MySQL prepared statement received an invalid connection index")
  if self.entry.stmts[connI].isNil:
    self.entry.stmts[connI] = await mysql_impl.prepareStmt(
      self.owner.pools.conns[connI].conn,
      self.sql,
      self.owner.pools.timeout
    )
  touchStmtEntry(self.entry)
  return self.entry.stmts[connI]


proc getPreparedRowsOnConn(
  self: MysqlPreparedStatement,
  connI: int,
  args: seq[PreparedParam]
): Future[(seq[seq[string]], DbRows)] {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "MySQL prepared statement received an invalid connection index")

  let stmt = await self.ensurePreparedStmt(connI)
  if connI >= self.resultBindCache.len:
    self.resultBindCache.setLen(connI + 1)
  if self.resultBindCache[connI].isNil:
    new(self.resultBindCache[connI])
  return mysql_impl.queryPreparedStmt(
    self.owner.pools.conns[connI].conn,
    stmt,
    args,
    self.owner.pools.timeout,
    self.resultBindCache[connI]
  ).await


proc getPreparedRows(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[(seq[seq[string]], DbRows)] {.async.} =
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
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
): Future[(seq[seq[string]], DbRows)] {.async.} =
  self.verifyCtx(ctx)
  return await self.getPreparedRowsOnConn(ctx.connI, args)


proc getPreparedAllRows(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[seq[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows)


proc getPreparedRow(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[Option[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some()


proc getPreparedAllRowsPlain(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[seq[seq[string]]] {.async.} =
  let (rows, _) = await self.getPreparedRows(args)
  return rows


proc getPreparedRowPlain(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[seq[string]] {.async.} =
  let (rows, _) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[string](0)
  return rows[0]


proc getPreparedAllRows(
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
): Future[seq[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(ctx, args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows)


proc getPreparedRow(
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
): Future[Option[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(ctx, args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some()


proc getPreparedAllRowsPlain(
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
): Future[seq[seq[string]]] {.async.} =
  let (rows, _) = await self.getPreparedRows(ctx, args)
  return rows


proc getPreparedRowPlain(
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
): Future[seq[string]] {.async.} =
  let (rows, _) = await self.getPreparedRows(ctx, args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[string](0)
  return rows[0]


proc execPreparedOnConn(
  self: MysqlPreparedStatement,
  connI: int,
  args: seq[PreparedParam]
) {.async.} =
  self.mustBeOpen()
  if connI < 0 or connI >= self.owner.pools.conns.len:
    raise newException(DbError, "MySQL prepared statement received an invalid connection index")

  let stmt = await self.ensurePreparedStmt(connI)
  await mysql_impl.execPreparedStmt(
    self.owner.pools.conns[connI].conn,
    stmt,
    args,
    self.owner.pools.timeout
  )


proc execPrepared(self: MysqlPreparedStatement, args: seq[PreparedParam]) {.async.} =
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
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
) {.async.} =
  self.verifyCtx(ctx)
  await self.execPreparedOnConn(ctx.connI, args)


proc preparedGet(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRows(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirst(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedGetPlain(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[seq[seq[string]]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRowsPlain(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirstPlain(self: MysqlPreparedStatement, args: seq[PreparedParam]): Future[seq[string]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRowPlain(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedExec(self: MysqlPreparedStatement, args: seq[PreparedParam]) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedGet(
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
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
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
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
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
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
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
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
  self: MysqlPreparedStatement,
  ctx: MysqlPreparedContext,
  args: seq[PreparedParam]
) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(ctx, args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc get*(self: MysqlPreparedStatement, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(args.toPreparedParams)


proc get*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(ctx, args.toPreparedParams)


proc get*(self: MysqlPreparedStatement, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(args.toPreparedParams)


proc get*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(ctx, args.toPreparedParams)


proc first*(self: MysqlPreparedStatement, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(args.toPreparedParams)


proc first*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(ctx, args.toPreparedParams)


proc first*(self: MysqlPreparedStatement, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(args.toPreparedParams)


proc first*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(ctx, args.toPreparedParams)


proc getPlain*(self: MysqlPreparedStatement, args: seq[string]): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(args.toPreparedParams)


proc getPlain*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: seq[string]): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(ctx, args.toPreparedParams)


proc getPlain*(self: MysqlPreparedStatement, args: JsonNode): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(args.toPreparedParams)


proc getPlain*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: JsonNode): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(ctx, args.toPreparedParams)


proc firstPlain*(self: MysqlPreparedStatement, args: seq[string]): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(args.toPreparedParams)


proc firstPlain*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: seq[string]): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(ctx, args.toPreparedParams)


proc firstPlain*(self: MysqlPreparedStatement, args: JsonNode): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(args.toPreparedParams)


proc firstPlain*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: JsonNode): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(ctx, args.toPreparedParams)


proc exec*(self: MysqlPreparedStatement, args: seq[string]) {.async.} =
  await self.preparedExec(args.toPreparedParams)


proc exec*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: seq[string]) {.async.} =
  await self.preparedExec(ctx, args.toPreparedParams)


proc exec*(self: MysqlPreparedStatement, args: JsonNode) {.async.} =
  await self.preparedExec(args.toPreparedParams)


proc exec*(self: MysqlPreparedStatement, ctx: MysqlPreparedContext, args: JsonNode) {.async.} =
  await self.preparedExec(ctx, args.toPreparedParams)


proc close*(self: MysqlPreparedStatement) {.async.} =
  if self.isNil or self.isClosed:
    return
  self.isClosed = true
  if not self.entry.isNil:
    if self.entry.refCount > 0:
      self.entry.refCount -= 1
    touchStmtEntry(self.entry)


proc flushStmt*(self: MysqlConnections, sql: string) {.async.} =
  if not hasPreparedEntry(self.pools.preparedCache, sql):
    return
  let entry = self.pools.preparedCache[sql]
  for i, stmt in entry.stmts:
    if stmt.isNil:
      continue
    try:
      mysql_impl.closePreparedStmt(stmt)
    except CatchableError:
      self.log.echoErrorMsg("close failed for prepared stmt: " & getCurrentExceptionMsg())
    entry.stmts[i] = nil
  self.pools.preparedCache.del(sql)


proc clearStmtCache*(self: MysqlConnections) {.async.} =
  let keys = toSeq(self.pools.preparedCache.keys)
  for sql in keys:
    await self.flushStmt(sql)


proc get*(self: RawMysqlQuery):Future[seq[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRows(self.queryString).await


proc getPlain*(self: RawMysqlQuery):Future[seq[seq[string]]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRowsPlain(self.queryString, self.placeHolder).await


proc exec*(self: RawMysqlQuery) {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  self.exec(self.queryString).await


proc first*(self: RawMysqlQuery):Future[Option[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRow(self.queryString).await


proc firstPlain*(self: RawMysqlQuery):Future[seq[string]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRowPlain(self.queryString, self.placeHolder).await


template seeder*(rdb:MysqlConnections, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table is empty.
  block:
    if rdb.table(tableName).count().waitFor == 0:
      body


template seeder*(rdb:MysqlConnections, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  block:
    if rdb.table(tableName).select(column).count().waitFor == 0:
      body
