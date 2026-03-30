import std/asyncdispatch
import std/deques
import std/atomics
import std/json
import std/monotimes
import std/options
import std/strformat
import std/strutils
import std/sequtils
import std/tables
import std/times
import ../../libs/postgres/postgres_lib
import ../../libs/postgres/postgres_impl
import ../../log
import ../database_types
import ../../prepared_param
import ./query/postgres_builder
import ./postgres_types

var gPreparedStmtCounter: Atomic[int]


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

proc getFreeConn(self: PostgresConnections | PostgresQuery | RawPostgresQuery): Future[int] {.async.} =
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
    var ms = poolRemainingMs(deadline)
    if ms < 1:
      ms = 1
    let ok = await withTimeout(w, ms)
    if not ok:
      removePoolWaiter(self.pools, w)
      return errorConnectionNum


proc returnConn(self: PostgresConnections | PostgresQuery | RawPostgresQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false
    wakeOnePoolWaiter(self.pools)


proc prepare*(self: PostgresConnections, sql: string): PostgresPreparedStatement =
  new(result)
  result.owner = self
  result.sql = sql
  result.stmtBaseName = &"allographer_stmt_{gPreparedStmtCounter.fetchAdd(1)}"
  result.stmtNames = newSeq[string](self.pools.conns.len)
  result.nArgs = countQuestionMarks(sql)


proc ensurePreparedStmt(self: PostgresPreparedStatement, connI: int): Future[string] {.async.} =
  if self.stmtNames[connI].len == 0:
    let stmtName = &"{self.stmtBaseName}_{connI}"
    await postgres_impl.prepare(
      self.owner.pools.conns[connI].conn,
      self.sql,
      self.owner.pools.timeout,
      stmtName,
      self.nArgs
    )
    self.stmtNames[connI] = stmtName
  return self.stmtNames[connI]


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
      # let size = dbRows[index][i].typ.size

      if typ == dbNull:
        response_row[key] = newJNull()
      elif [dbInt, dbUInt].contains(typ):
        response_row[key] = newJInt(row.parseInt)
      elif [dbDecimal, dbFloat].contains(typ):
        response_row[key] = newJFloat(row.parseFloat)
      elif [dbBool].contains(typ):
        if row == "f":
          response_row[key] = newJBool(false)
        elif row == "t":
          response_row[key] = newJBool(true)
      elif [dbJson].contains(typ):
        response_row[key] = row.parseJson
      elif [dbFixedChar, dbVarchar].contains(typ):
        if row == "NULL":
          response_row[key] = newJNull()
        else:
          response_row[key] = newJString(row)
      else:
        response_row[key] = newJString(row)
    
    response_table[index] = response_row
  return response_table


# ================================================================================
# private exec
# ================================================================================

const pgInfoSchemaColumnsQuery =
  "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = $1"

proc getCachedColumnTypes(self: PostgresQuery, connI: int): Future[seq[Row]] {.async.} =
  let table = self.query["table"].getStr
  if self.pools.columnTypeCache.hasKey(table):
    return self.pools.columnTypeCache[table]
  let args = %*[%*{"key": "table", "value": table}]
  let (columns, _) = postgres_impl.query(
    self.pools.conns[connI].conn, pgInfoSchemaColumnsQuery, args, self.pools.timeout
  ).await
  self.pools.columnTypeCache[table] = columns
  return columns


proc getAllRows(self:PostgresQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let (rows, dbRows) = postgres_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]


proc getAllRowsPlain(self:PostgresQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let (rows, _) = postgres_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  
  return rows


proc getRow(self:PostgresQuery, queryString:string, connI:int=0):Future[Option[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await

  if connI == errorConnectionNum:
    return

  let (rows, dbRows) = postgres_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some # seq[JsonNode]


proc getRowPlain(self:PostgresQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  
  let (rows, _) = postgres_impl.query(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  return rows[0]


proc exec(self:PostgresQuery, queryString:string) {.async.} =
  ## args is `JObject`
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let columns = getCachedColumnTypes(self, connI).await
  postgres_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await


proc insertId(self:PostgresQuery, queryString:string, key:string):Future[string] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let columns = getCachedColumnTypes(self, connI).await
  let (rows, _) = postgres_impl.execGetValue(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await
  return rows[0][0]


proc getAllRows(self:RawPostgresQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let queryString = queryString.questionToDaller()

  let (rows, dbRows) = postgres_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]


proc getAllRowsPlain(self:RawPostgresQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let queryString = queryString.questionToDaller()

  let (rows, _) = postgres_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  
  return rows


proc getRow(self:RawPostgresQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let queryString = queryString.questionToDaller()

  let (rows, dbRows) = postgres_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some # seq[JsonNode]


proc getRowPlain(self:RawPostgresQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let queryString = queryString.questionToDaller()
  
  let (rows, _) = postgres_impl.rawQuery(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await
  return rows[0]


proc exec(self:RawPostgresQuery, queryString:string) {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await

  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let queryString = queryString.questionToDaller()

  postgres_impl.rawExec(
    self.pools.conns[connI].conn,
    queryString,
    self.placeHolder,
    self.pools.timeout
  ).await


proc getColumn(self:PostgresQuery, queryString:string):Future[seq[string]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
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

  return postgres_impl.getColumns(self.pools.conns[connI].conn, queryString, strArgs, self.pools.timeout).await


proc transactionStart(self:PostgresConnections|PostgresQuery) {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  self.isInTransaction = true
  self.transactionConn = connI

  postgres_impl.exec(self.pools.conns[connI].conn, "BEGIN", newJArray(), newSeq[seq[string]](), self.pools.timeout).await


proc transactionEnd(self:PostgresConnections|PostgresQuery, query:string) {.async.} =
  postgres_impl.exec(self.pools.conns[self.transactionConn].conn, query, newJArray(), newSeq[seq[string]](), self.pools.timeout).await
  self.returnConn(self.transactionConn).await
  self.transactionConn = 0
  self.isInTransaction = false


proc getPreparedRows(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[(seq[seq[string]], DbRows)] {.async.} =
  var connI = self.owner.transactionConn
  if not self.owner.isInTransaction:
    connI = getFreeConn(self.owner).await
  defer:
    if not self.owner.isInTransaction:
      self.owner.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let stmtName = await self.ensurePreparedStmt(connI)
  return postgres_impl.preparedQuery(
    self.owner.pools.conns[connI].conn,
    args,
    self.nArgs,
    self.owner.pools.timeout,
    stmtName
  ).await


proc getPreparedAllRows(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[seq[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows)


proc getPreparedRow(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[Option[JsonNode]] {.async.} =
  let (rows, dbRows) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some()


proc getPreparedAllRowsPlain(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[seq[seq[string]]] {.async.} =
  let (rows, _) = await self.getPreparedRows(args)
  return rows


proc getPreparedRowPlain(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[seq[string]] {.async.} =
  let (rows, _) = await self.getPreparedRows(args)
  if rows.len == 0:
    self.owner.log.echoErrorMsg(self.sql)
    return newSeq[string](0)
  return rows[0]


proc execPrepared(self: PostgresPreparedStatement, args: seq[PreparedParam]) {.async.} =
  var connI = self.owner.transactionConn
  if not self.owner.isInTransaction:
    connI = getFreeConn(self.owner).await
  defer:
    if not self.owner.isInTransaction:
      self.owner.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let stmtName = await self.ensurePreparedStmt(connI)
  await postgres_impl.preparedExec(
    self.owner.pools.conns[connI].conn,
    args,
    self.nArgs,
    self.owner.pools.timeout,
    stmtName
  )


proc preparedGet(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[seq[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRows(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirst(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[Option[JsonNode]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRow(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedGetPlain(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[seq[seq[string]]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedAllRowsPlain(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedFirstPlain(self: PostgresPreparedStatement, args: seq[PreparedParam]): Future[seq[string]] {.async.} =
  try:
    self.owner.log.logger(self.sql)
    return await self.getPreparedRowPlain(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc preparedExec(self: PostgresPreparedStatement, args: seq[PreparedParam]) {.async.} =
  try:
    self.owner.log.logger(self.sql)
    await self.execPrepared(args)
  except CatchableError:
    self.owner.log.echoErrorMsg(self.sql)
    self.owner.log.echoErrorMsg(getCurrentExceptionMsg())
    raise getCurrentException()


proc get*(self: PostgresPreparedStatement, args: seq[string]): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(args.toPreparedParams)


proc get*(self: PostgresPreparedStatement, args: JsonNode): Future[seq[JsonNode]] {.async.} =
  return await self.preparedGet(args.toPreparedParams)


proc first*(self: PostgresPreparedStatement, args: seq[string]): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(args.toPreparedParams)


proc first*(self: PostgresPreparedStatement, args: JsonNode): Future[Option[JsonNode]] {.async.} =
  return await self.preparedFirst(args.toPreparedParams)


proc getPlain*(self: PostgresPreparedStatement, args: seq[string]): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(args.toPreparedParams)


proc getPlain*(self: PostgresPreparedStatement, args: JsonNode): Future[seq[seq[string]]] {.async.} =
  return await self.preparedGetPlain(args.toPreparedParams)


proc firstPlain*(self: PostgresPreparedStatement, args: seq[string]): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(args.toPreparedParams)


proc firstPlain*(self: PostgresPreparedStatement, args: JsonNode): Future[seq[string]] {.async.} =
  return await self.preparedFirstPlain(args.toPreparedParams)


proc exec*(self: PostgresPreparedStatement, args: seq[string]) {.async.} =
  await self.preparedExec(args.toPreparedParams)


proc exec*(self: PostgresPreparedStatement, args: JsonNode) {.async.} =
  await self.preparedExec(args.toPreparedParams)


# ================================================================================
# public exec
# ================================================================================

# ==================== return json ====================
proc get*(self: PostgresQuery):Future[seq[JsonNode]] {.async.} =
  var sql = self.selectBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc first*(self: PostgresQuery):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFirstBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self: PostgresQuery, id:string, key="id"):Future[Option[JsonNode]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value": id})
  var sql = self.selectFindBuilder(key)
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self: PostgresQuery, id:int, key="id"):Future[Option[JsonNode]] {.async.} =
  return self.find($id, key).await


# ==================== return string ====================
proc getPlain*(self:PostgresQuery):Future[seq[seq[string]]] {.async.} =
  var sql = self.selectBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getAllRowsPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc firstPlain*(self:PostgresQuery):Future[seq[string]] {.async.} =
  var sql = self.selectFirstBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:PostgresQuery, id: string, key="id"):Future[seq[string]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  var sql = self.selectFindBuilder(key)
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:PostgresQuery, id: int, key="id"):Future[seq[string]] {.async.} =
  return self.findPlain($id, key).await


# ==================== insert JsonNode ====================
proc insert*(self:PostgresQuery, items:JsonNode) {.async.} =
  ## items is `JObject`
  var sql = self.insertValueBuilder(items)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*(self:PostgresQuery, items:seq[JsonNode]) {.async.} =
  var sql = self.insertValuesBuilder(items)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*(self:PostgresQuery, items:JsonNode, key="id"):Future[string] {.async.} =
  var sql = self.insertValueBuilder(items)
  sql.add(&" RETURNING \"{key}\"")
  sql = questionToDaller(sql)
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*(self: PostgresQuery, items: seq[JsonNode], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    var sql = self.insertValueBuilder(item)
    sql.add(&" RETURNING \"{key}\"")
    sql = questionToDaller(sql)
    self.log.logger(sql)
    result[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()


# ==================== insert Object ====================
proc insert*[T](self:PostgresQuery, items:T) {.async.} =
  var sql = self.insertValueBuilder(%items)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc insert*[T](self:PostgresQuery, items:seq[T]) {.async.} =
  let items = items.mapIt(%it)
  var sql = self.insertValuesBuilder(items)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*[T](self:PostgresQuery, items:T, key="id"):Future[string] {.async.} =
  var sql = self.insertValueBuilder(%items)
  sql.add(&" RETURNING \"{key}\"")
  sql = questionToDaller(sql)
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*[T](self: PostgresQuery, items: seq[T], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    var sql = self.insertValueBuilder(%item)
    sql.add(&" RETURNING \"{key}\"")
    sql = questionToDaller(sql)
    self.log.logger(sql)
    result[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()


# ==================== update ====================
proc update*(self: PostgresQuery, items: JsonNode){.async.} =
  var sql = self.updateBuilder(items)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc update*[T](self: PostgresQuery, items: T){.async.} =
  var sql = self.updateBuilder(%items)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self: PostgresQuery){.async.} =
  var sql = self.deleteBuilder()
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self: PostgresQuery, id: int, key="id"){.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  var sql = self.deleteByIdBuilder(id, key)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  self.exec(sql).await


proc columns*(self:PostgresQuery):Future[seq[string]] {.async.} =
  ## get columns sequence from table
  var sql = self.columnBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getColumn(sql).await
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc count*(self:PostgresQuery):Future[int] {.async.} =
  var sql = self.countBuilder()
  sql = questionToDaller(sql)
  self.log.logger(sql)
  let response =  self.getRow(sql).await

  if response.isSome:
    return response.get["aggregate"].getInt()
  else:
    return 0


proc min*(self:PostgresQuery, column:string):Future[Option[string]] {.async.} =
  var sql = self.minBuilder(column)
  sql = questionToDaller(sql)
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


proc max*(self:PostgresQuery, column:string):Future[Option[string]] {.async.} =
  var sql = self.maxBuilder(column)
  sql = questionToDaller(sql)
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


proc avg*(self:PostgresQuery, column:string):Future[Option[float]]{.async.} =
  var sql = self.avgBuilder(column)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  let response =  await self.getRow(sql)
  if response.isSome:
    return response.get["aggregate"].getFloat().some
  else:
    return none(float)


proc sum*(self:PostgresQuery, column:string):Future[Option[float]]{.async.} =
  var sql = self.sumBuilder(column)
  sql = questionToDaller(sql)
  self.log.logger(sql)
  let response = await self.getRow(sql)
  if response.isSome:
    return response.get["aggregate"].getFloat().some
  else:
    return none(float)


proc begin*(self:PostgresConnections) {.async.} =
  self.log.logger("BEGIN")
  self.transactionStart().await


proc rollback*(self:PostgresConnections) {.async.} =
  self.log.logger("ROLLBACK")
  self.transactionEnd("ROLLBACK").await


proc commit*(self:PostgresConnections) {.async.} =
  self.log.logger("COMMIT")
  self.transactionEnd("COMMIT").await


proc get*(self: RawPostgresQuery):Future[seq[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRows(self.queryString).await


proc getPlain*(self: RawPostgresQuery):Future[seq[seq[string]]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRowsPlain(self.queryString, self.placeHolder).await


proc exec*(self: RawPostgresQuery) {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  self.exec(self.queryString).await


proc first*(self: RawPostgresQuery):Future[Option[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRow(self.queryString).await


proc firstPlain*(self: RawPostgresQuery):Future[seq[string]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRowPlain(self.queryString, self.placeHolder).await


proc deallocatePreparedStmtSafely(self: PostgresPreparedStatement, connI: int, stmtName: string): Future[void] {.async.} =
  try:
    await postgres_impl.deallocate(self.owner.pools.conns[connI].conn, stmtName, self.owner.pools.timeout)
  except CatchableError:
    self.owner.log.echoErrorMsg("deallocate failed for " & stmtName & ": " & getCurrentExceptionMsg())


proc close*(self: PostgresPreparedStatement) {.async.} =
  var futs: seq[Future[void]]
  for i, stmtName in self.stmtNames:
    if stmtName.len == 0:
      continue
    futs.add(self.deallocatePreparedStmtSafely(i, stmtName))
  if futs.len > 0:
    await all(futs)
  for i in 0 ..< self.stmtNames.len:
    self.stmtNames[i] = ""


template seeder*(rdb:PostgresConnections, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table is empty.
  block:
    if rdb.table(tableName).count().waitFor == 0:
      `body`


template seeder*(rdb:PostgresConnections, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  block:
    if rdb.table(tableName).select(column).count().waitFor == 0:
      `body`
