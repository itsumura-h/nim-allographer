import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/sequtils
import std/times
import ../../libs/surreal/surreal_lib
import ../../libs/surreal/surreal_impl
import ../../log
import ../../enums
import ../database_types
import ./query/surreal_builder
import ./surreal_types
import ./surreal_query


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:SurrealConnections | SurrealQuery | RawSurrealQuery):Future[int] {.async.} =
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


proc returnConn(self:SurrealConnections | SurrealQuery | RawSurrealQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false


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
  return rows.toSeq # seq[JsonNode]


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
  return rows.toSeq()


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
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  let res = self.getRow(sql).await
  if res.isSome():
    return SurrealId.new(res.get()[key].getStr())
  else:
    return SurrealId.new()


proc insertId*(self: SurrealQuery, items: seq[JsonNode], key="id"):Future[seq[SurrealId]] {.async.} =
  result = newSeq[SurrealId](items.len)
  var sql = self.insertValuesBuilder(items)
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
  let items = items.mapIt(%it)
  var sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql).await


proc insertId*[T](self:SurrealQuery, items:T, key="id"):Future[SurrealId] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/insert
  let sql = self.insertValueBuilder(%items)
  self.log.logger(sql)
  let res = self.getRow(sql).await
  if res.isSome():
    return SurrealId.new(res.get()[key].getStr())
  else:
    return SurrealId.new()


proc insertId*[T](self: SurrealQuery, items: seq[T], key="id"):Future[seq[SurrealId]] {.async.} =
  result = newSeq[SurrealId](items.len)
  let items = items.mapIt(%it)
  var sql = self.insertValuesBuilder(items)
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
    for (key, value) in resp[0]["result"]["fd"].pairs:
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
    return response.get["avg"].getStr().parseFloat()
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
