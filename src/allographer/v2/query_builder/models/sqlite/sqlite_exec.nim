import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../libs/sqlite/sqlite_impl
import ../../log
import ../database_types
import ./query/sqlite_builder
import ./sqlite_types


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:SqliteConnections | SqliteQuery | RawSqliteQuery):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.conns.len:
      if not self.pools.conns[i].isBusy:
        self.pools.conns[i].isBusy = true
        when defined(check_pool):
          echo "=== getFreeConn ", i
        return i
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.pools.timeout:
      return errorConnectionNum


proc returnConn(self: SqliteConnections | SqliteQuery | RawSqliteQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false


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

proc getAllRows(self:SqliteQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
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
    return

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
    return

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
    return

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
    return

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
    return

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
    return

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
    return

  let table = self.query["table"].getStr
  let columnGetQuery = &"PRAGMA table_info(\"{table}\")"
  let columns = sqlite_impl.getColumnTypes(self.pools.conns[connI].conn, columnGetQuery).await

  sqlite_impl.exec(self.pools.conns[connI].conn, queryString, self.placeHolder, columns, self.pools.timeout).await


proc exec(self:RawSqliteQuery, queryString:string, args:JsonNode) {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  sqlite_impl.exec(self.pools.conns[connI].conn, queryString, args, self.pools.timeout).await


proc insertId(self:SqliteQuery, queryString:string, key:string):Future[string]{.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let table = self.query["table"].getStr
  let columnGetQuery = &"PRAGMA table_info(\"{table}\")"
  let columns = sqlite_impl.getColumnTypes(self.pools.conns[connI].conn, columnGetQuery).await

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
    return

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
    return
  self.isInTransaction = true
  self.transactionConn = connI
  sqlite_impl.exec(self.pools.conns[connI].conn, "BEGIN", newJArray(), self.pools.timeout).await


proc transactionEnd(self:SqliteConnections, query:string) {.async.} =
  defer:
    self.returnConn(self.transactionConn).await
    self.transactionConn = 0
    self.isInTransaction = false

  sqlite_impl.exec(self.pools.conns[self.transactionConn].conn, query, newJArray(), self.pools.timeout).await


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


# ==================== return Object ====================
# proc get*[T](self: SqliteQuery, typ:typedesc[T]):Future[seq[T]] {.async.} =
#   var sql = self.selectBuilder()
#   try:
#     self.log.logger(sql)
#     let rows = self.getAllRows(sql).await
#     for row in rows:
#       result.add(row.to(typ))
#   except CatchableError:
#     self.log.echoErrorMsg(sql)
#     self.log.echoErrorMsg( getCurrentExceptionMsg() )
#     raise getCurrentException()


# proc first*[T](self: SqliteQuery, typ:typedesc[T]):Future[Option[T]] {.async.} =
#   var sql = self.selectFirstBuilder()
#   try:
#     self.log.logger(sql)
#     let row = self.getRow(sql).await
#     if row.isSome():
#       return row.get().to(typ).some()
#     else:
#       return none(typ)
#   except CatchableError:
#     self.log.echoErrorMsg(sql)
#     self.log.echoErrorMsg( getCurrentExceptionMsg() )
#     raise getCurrentException()


# proc find*[T](self: SqliteQuery, id:string, typ:typedesc[T], key="id"):Future[Option[T]] {.async.} =
#   self.placeHolder.add(%*{"key":key, "value": id})
#   var sql = self.selectFindBuilder(key)
#   try:
#     self.log.logger(sql)
#     let row = self.getRow(sql).await
#     if row.isSome():
#       return row.get().to(typ).some()
#     else:
#       return none(typ)
#   except CatchableError:
#     self.log.echoErrorMsg(sql)
#     self.log.echoErrorMsg( getCurrentExceptionMsg() )
#     raise getCurrentException()


# proc find*[T](self: SqliteQuery, id:int, typ:typedesc[T], key="id"):Future[Option[T]] {.async.} =
#   return self.find($id, typ, key).await


# ==================== insert ====================
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


proc update*(self:SqliteQuery, items:JsonNode) {.async.} =
  let sql = self.updateBuilder(items)
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


template seeder*(rdb:SqliteConnections, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table is empty.
  block:
    if rdb.table(tableName).count().waitFor == 0:
      body


template seeder*(rdb:SqliteConnections, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  block:
    if rdb.table(tableName).select(column).count().waitFor == 0:
      body
