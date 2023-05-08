import std/algorithm
import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import ../databases/database
import ../types
import ../utils
import ./builders


proc selectSql*(self: Rdb):string =
  result = self.selectBuilder() & $self.placeHolder
  echo result

proc toJson(driver:Driver, results:openArray[seq[string]], dbRows:DbRows):seq[JsonNode] =
  if driver == SurrealDB:
    let res = results[0][0].parseJson()["result"]
    if res.kind == JArray:
      var resp = newSeq[JsonNode](res.len)
      var i = 0
      for row in res:
        resp[i] = row
        i.inc()
      return resp
    else:
      return @[res]
 
  var response_table = newSeq[JsonNode](results.len)
  for index, rows in results.pairs:
    var response_row = newJObject()
    for i, row in rows:
      let key = dbRows[index][i].name
      let typ = dbRows[index][i].typ.kind
      let kindName = dbRows[index][i].typ.name
      let size = dbRows[index][i].typ.size

      case driver:
      of SQLite3:
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
      of MySQL, MariaDB:
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
      of PostgreSQL:
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
        else:
          response_row[key] = newJString(row)
      else:
        discard

    response_table[index] = response_row
  return response_table

proc getAllRows(self:Rdb | RawQueryRdb, sqlString:string, args:seq[string]):Future[seq[JsonNode]] {.async.} =
  let (rows, dbRows) = self.conn.query(
    self.driver,
    sqlString,
    args,
    self.isInTransaction,
    self.transactionConn
  ).await

  if rows.len == 0:
    self.log.echoErrorMsg(sqlString & $args)
    return newSeq[JsonNode](0)
  return toJson(self.driver, rows, dbRows) # seq[JsonNode]

proc getRowsPlain(self:Rdb | RawQueryRdb, sqlString:string, args:seq[string]):Future[seq[seq[string]]] {.async.} =
  return self.conn.queryPlain(
    self.driver,
    sqlString,
    args,
    self.isInTransaction,
    self.transactionConn
  ).await

proc getRow(self:Rdb | RawQueryRdb, sqlString:string, args:seq[string]):Future[Option[JsonNode]] {.async.} =
  let (rows, dbColumns) = self.conn.query(
    self.driver,
    sqlString,
    args,
    self.isInTransaction,
    self.transactionConn
  ).await
  if rows.len == 0:
    self.log.echoErrorMsg(sqlString & $args)
    return none(JsonNode)
  return toJson(self.driver, rows, dbColumns)[0].some


proc getColumn(self:Rdb, sqlString:string, args:seq[string]):Future[seq[string]] {.async.} =
  return self.conn.getColumns(self.driver, sqlString, args).await

proc getRowPlain(self:Connections, driver:Driver, sqlString:string, args:seq[string]):Future[seq[string]] {.async.} =
  return self.queryPlain(driver, sqlString, args).await[0]

proc orm[T](rows:openArray[JsonNode], typ:typedesc[T]):seq[T] =
  var response = newSeq[T](rows.len)
  for i, row in rows:
    response[i] = row.to(T)
  return response

proc orm[T](row:JsonNode, typ:typedesc[T]):T =
  return row.to(typ)

proc orm[T](row:Option[JsonNode], typ:typedesc[T]):Option[T] =
  if row.isSome:
    return row.get.to(T).some
  else:
    return none(T)

# proc cleanUp(self:Rdb) =
#   self.query = newJObject()
#   self.sqlString = ""
#   self.placeHolder = @[]

# =============================================================================

proc toSql*(self: Rdb): string =
  return self.selectBuilder()

proc columns*(self:Rdb):Future[seq[string]] {.async.} =
  ## get columns sequence from table
  # defer: self.cleanUp()
  let sql = self.columnBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getColumn(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[string]()

proc get*(self: Rdb):Future[seq[JsonNode]] {.async.} =
  # defer: self.cleanUp()
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getAllRows(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode](0)

proc get*[T](self: Rdb, typ: typedesc[T]): Future[seq[T]] {.async.} =
  # defer: self.cleanUp()
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getAllRows(self, sql, self.placeHolder).await.orm(typ)
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[typ.type](0)

proc getPlain*(self:Rdb):Future[seq[seq[string]]] {.async.} =
  # defer: self.cleanUp()
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getRowsPlain(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[seq[string]](0)

proc get*(self: RawQueryRdb):Future[seq[JsonNode]]{.async.} =
  ## It is only used with raw()
  # defer: self.cleanUp()
  try:
    self.log.logger(self.sqlString, self.placeHolder)
    return getAllRows(self, self.sqlString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.sqlString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode](0)

proc getPlain*(self:RawQueryRdb):Future[seq[seq[string]]] {.async.} =
  # defer: self.cleanUp()
  try:
    self.log.logger(self.sqlString, self.placeHolder)
    return getRowsPlain(self, self.sqlString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.sqlString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[seq[string]](0)

proc get*[T](self: RawQueryRdb, typ: typedesc[T]):Future[seq[T]]{.async.} =
  ## It is only used with raw()
  # defer: self.cleanUp()
  try:
    self.log.logger(self.sqlString, self.placeHolder)
    return getAllRows(self, self.sqlString, self.placeHolder).await.orm(typ)
  except Exception:
    self.log.echoErrorMsg(self.sqlString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[typ.type](0)

proc first*(self: Rdb):Future[Option[JsonNode]] {.async.} =
  # defer: self.cleanUp()
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)

proc first*(self: RawQueryRdb):Future[Option[JsonNode]] {.async.} =
  # defer: self.cleanUp()
  try:
    self.log.logger(self.sqlString, self.placeHolder)
    return getRow(self, self.sqlString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.sqlString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)

proc first*[T](self: Rdb, typ: typedesc[T]):Future[Option[T]] {.async.} =
  # defer: self.cleanUp()
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await.get.orm(typ).some
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(typ.type)

proc firstPlain*(self: Rdb):Future[seq[string]]{.async.} =
  # defer: self.cleanUp()
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql, self.placeHolder)
    return getRowPlain(self.conn, self.driver, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[string](0)

proc firstPlain*(self: RawQueryRdb):Future[seq[string]]{.async.} =
  # defer: self.cleanUp()
  try:
    self.log.logger(self.sqlString, self.placeHolder)
    return getRowPlain(self.conn, self.driver, self.sqlString, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(self.sqlString & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[string](0)

proc find*(self: Rdb, id: string, key="id"):Future[Option[JsonNode]]{.async.} =
  # defer: self.cleanUp()
  self.placeHolder.add(id)
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)

proc find*(self: Rdb, id: int, key="id"):Future[Option[JsonNode]]{.async.} =
  return self.find($id, key).await

proc find*[T](self: Rdb, id: int, typ:typedesc[T], key="id"):Future[Option[T]]{.async.} =
  # defer: self.cleanUp()
  self.placeHolder.add($id)
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql, self.placeHolder)
    return getRow(self, sql, self.placeHolder).await.get.orm(typ).some
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(typ.type)

proc findPlain*(self:Rdb, id:int, key="id"):Future[seq[string]]{.async.} =
  # defer: self.cleanUp()
  self.placeHolder.add($id)
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql, self.placeHolder)
    return getRowPlain(self.conn, self.driver, sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql & $self.placeHolder)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[string](0)


# ==================== INSERT ====================

proc insertSql*(self: Rdb, items: JsonNode):string =
  result = self.insertValueBuilder(items)
  echo result

proc insertId(self:Rdb, sqlString:string, placeHolder:seq[string], key:string):Future[int]{.async.} =
  if self.driver == SQLite3:
    self.log.logger(sqlString, placeHolder)
    self.conn.exec(self.driver, sqlString, placeHolder, self.isInTransaction, self.transactionConn).await
    let (rows, _) = self.conn.query(self.driver, "SELECT last_insert_rowid()", @[], self.isInTransaction, self.transactionConn).await
    return rows[0][0].parseInt
  elif self.driver == MySQL or self.driver == MariaDB:
    self.log.logger(sqlString, placeHolder)
    self.conn.exec(self.driver, sqlString, placeHolder, self.isInTransaction, self.transactionConn).await
    let (rows, _) = self.conn.query(self.driver, "SELECT LAST_INSERT_ID()", @[], self.isInTransaction, self.transactionConn).await
    return rows[0][0].parseInt
  else:
    var key = key
    quote(key, self.driver)
    var sqlString = sqlString
    sqlString.add(&" RETURNING {key}")
    self.log.logger(sqlString, placeHolder)
    let (rows, _) = self.conn.query(self.driver, sqlString, placeHolder, self.isInTransaction, self.transactionConn).await
    return rows[0][0].parseInt

proc insert*(self: Rdb, items: JsonNode){.async.} =
  # defer: self.cleanUp()
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(self.driver, sql, self.placeHolder, self.isInTransaction, self.transactionConn).await

proc insert*(self: Rdb, rows: seq[JsonNode]){.async.} =
  # defer: self.cleanUp()
  let sql = self.insertValuesBuilder(rows)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(self.driver, sql, self.placeHolder, self.isInTransaction, self.transactionConn).await

proc inserts*(self: Rdb, rows: seq[JsonNode]){.async.} =
  # defer: self.cleanUp()
  for row in rows:
    let sqlString = self.insertValueBuilder(row)
    self.log.logger(sqlString, self.placeHolder)
    self.conn.exec(self.driver, sqlString, self.placeHolder, self.isInTransaction, self.transactionConn).await
    self.placeHolder = @[]

proc insertId*(self: Rdb, items: JsonNode, key="id"):Future[int] {.async.} =
  # defer: self.cleanUp()
  let sql = self.insertValueBuilder(items)
  return self.insertId(sql, self.placeHolder, key).await

proc insertId*(self: Rdb, rows: seq[JsonNode], key="id"):Future[int] {.async.} =
  # defer: self.cleanUp()
  let sql = self.insertValuesBuilder(rows)
  result = self.insertId(sql, self.placeHolder, key).await
  self.placeHolder = @[]

proc insertsID*(self: Rdb, rows: seq[JsonNode], key="id"):Future[seq[int]]{.async.} =
  # defer: self.cleanUp()
  var response = newSeq[int](rows.len)
  for i, row in rows:
    let sqlString = self.insertValueBuilder(row)
    response[i] = self.insertId(sqlString, self.placeHolder, key).await
    self.placeHolder = @[]
  return response

# ==================== UPDATE ====================

proc updateSql*(self: Rdb, items: JsonNode):string =
  # defer: self.cleanUp()
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

  let placeHolder = updatePlaceHolder & self.placeHolder
  let sqlString = self.updateBuilder(items)

  result = sqlString & $placeHolder
  echo result

proc update*(self: Rdb, items: JsonNode){.async.} =
  # defer: self.cleanUp()
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
  self.conn.exec(self.driver, sql, self.placeHolder, self.isInTransaction, self.transactionConn).await

# ==================== DELETE ====================

proc deleteSql*(self: Rdb):string =
  result = self.deleteBuilder() & $self.placeHolder
  echo result

proc delete*(self: Rdb){.async.} =
  # defer: self.cleanUp()
  let sql = self.deleteBuilder()
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(self.driver, sql, self.placeHolder, self.isInTransaction, self.transactionConn).await

proc delete*(self: Rdb, id: int, key="id"){.async.} =
  # defer: self.cleanUp()
  self.placeHolder.add($id)
  let sql = self.deleteByIdBuilder(id, key)
  self.log.logger(sql, self.placeHolder)
  self.conn.exec(self.driver, sql, self.placeHolder, self.isInTransaction, self.transactionConn).await

# ==================== EXEC ====================

proc exec*(self: RawQueryRdb){.async.} =
  ## It is only used with raw()
  # defer: self.cleanUp()
  self.log.logger(self.sqlString, self.placeHolder)
  self.conn.exec(self.driver, self.sqlString, self.placeHolder, self.isInTransaction, self.transactionConn).await


# ==================== Transaction ====================

proc begin*(self:Rdb):Future[int] {.async.} =
  # defer: self.cleanUp()
  self.log.logger("BEGIN")
  let connI = self.conn.transactionStart(self.driver).await
  return connI

proc rollback*(self:Rdb, connI:int) {.async.} =
  # defer: self.cleanUp()
  self.log.logger("ROLLBACK")
  self.conn.transactionEnd(self.driver, connI, "ROLLBACK").await

proc commit*(self:Rdb, connI:int) {.async.} =
  # defer: self.cleanUp()
  self.log.logger("COMMIT")
  self.conn.transactionEnd(self.driver, connI, "COMMIT").await

# ==================== Aggregates ====================

proc count*(self:Rdb):Future[int]{.async.} =
  # defer: self.cleanUp()
  let sql = self.countBuilder()
  self.log.logger(sql, self.placeHolder)
  let response =  self.getRow(sql, self.placeHolder).await
  if response.isSome:
    case self.driver
    of SQLite3:
      return response.get["aggregate"].getStr().parseInt()
    of MySQL, MariaDB:
      return response.get["aggregate"].getInt()
    of PostgreSQL:
      return response.get["aggregate"].getInt()
    else:
      discard
  else:
    return 0

proc max*(self:Rdb, column:string):Future[Option[string]]{.async.} =
  # defer: self.cleanUp()
  let sql = self.maxBuilder(column)
  self.log.logger(sql, self.placeHolder)
  let response =  self.getRow(sql, self.placeHolder).await
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

proc min*(self:Rdb, column:string):Future[Option[string]]{.async.} =
  # defer: self.cleanUp()
  let sql = self.minBuilder(column)
  self.log.logger(sql, self.placeHolder)
  let response =  await self.getRow(sql, self.placeHolder)
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

proc avg*(self:Rdb, column:string):Future[Option[float]]{.async.} =
  # defer: self.cleanUp()
  let sql = self.avgBuilder(column)
  self.log.logger(sql, self.placeHolder)
  let response =  await self.getRow(sql, self.placeHolder)
  if response.isSome:
    case self.driver
    of SQLite3:
      return response.get["aggregate"].getStr().parseFloat.some
    else:
      return response.get["aggregate"].getFloat.some
  else:
    return none(float)

proc sum*(self:Rdb, column:string):Future[Option[float]]{.async.} =
  # defer: self.cleanUp()
  let sql = self.sumBuilder(column)
  self.log.logger(sql, self.placeHolder)
  let response = await self.getRow(sql, self.placeHolder)
  if response.isSome:
    case self.driver
    of SQLite3:
      return response.get["aggregate"].getStr.parseFloat.some
    else:
      return response.get["aggregate"].getFloat.some
  else:
    return none(float)


# ==================== Paginate ====================

from grammars import table, where, limit, offset, orderBy, Order

proc paginate*(self:Rdb, display:int, page:int=1):Future[JsonNode]{.async.} =
  # defer: self.cleanUp()
  let tableName = self.query["table"].getStr()
  if not page > 0: raise newException(Exception, "Arg page should be larger than 0")
  let total = self.table(tableName).count().await
  let offset = (page - 1) * display
  let currentPage = self.table(tableName).limit(display).offset(offset).get().await
  let count = currentPage.len()
  let hasMorePages = if page * display < total: true else: false
  let lastPage = int(total / display)
  let nextPage = if page + 1 <= lastPage: page + 1 else: lastPage
  let perPage = display
  let previousPage = if page - 1 > 0: page - 1 else: 1
  return %*{
    "count": count,
    "currentPage": currentPage,
    "hasMorePages": hasMorePages,
    "lastPage": lastPage,
    "nextPage": nextPage,
    "perPage": perPage,
    "previousPage": previousPage,
    "total": total
  }


proc getFirstItem(self:Rdb, keyArg:string, order:Order=Asc):Future[int]{.async.} =
  var sqlString = self.sqlString
  var quoteKey = keyArg
  quote(quoteKey, self.driver)
  if order == Asc:
    sqlString = &"{sqlString} ORDER BY {quoteKey} ASC LIMIT 1"
  else:
    sqlString = &"{sqlString} ORDER BY {quoteKey} DESC LIMIT 1"
  let row = await self.getRow(sqlString, self.placeHolder)
  let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
  if row.isSome:
    return row.get[key].getInt
  else:
    return 0


proc getLastItem(self:Rdb, keyArg:string, order:Order=Asc):Future[int]{.async.} =
  var sqlString = self.sqlString
  var quoteKey = keyArg
  quote(quoteKey, self.driver)
  if order == Asc:
    sqlString = &"{sqlString} ORDER BY {quoteKey} DESC LIMIT 1"
  else:
    sqlString = &"{sqlString} ORDER BY {quoteKey} ASC LIMIT 1"
  let row = await self.getRow(sqlString, self.placeHolder)
  let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
  if row.isSome:
    return row.get[key].getInt
  else:
    return 0


proc fastPaginate*(self:Rdb, display:int, key="id", order:Order=Asc):Future[JsonNode]{.async.} =
  # defer: self.cleanUp()
  var sql = self.selectBuilder()
  var quoteKey = key
  quote(quoteKey, self.driver)
  if order == Asc:
    sql = &"{sql} ORDER BY {quoteKey} ASC LIMIT {display + 1}"
  else:
    sql = &"{sql} ORDER BY {quoteKey} DESC LIMIT {display + 1}"
  self.log.logger(sql, self.placeHolder)
  var currentPage = self.getAllRows(sql, self.placeHolder).await
  if currentPage.len > 0:
    let newKey = if key.contains("."): key.split(".")[1] else: key
    let nextId = currentPage[currentPage.len-1][newKey].getInt()
    var hasNextId = true
    if currentPage.len > display:
      discard currentPage.pop()
    else:
      hasNextId = false
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": nextId,
      "hasNextId": hasNextId
    }
  else:
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": 0,
      "hasNextId": false
    }


proc fastPaginateNext*(self:Rdb, display, id:int, key="id", order:Order=Asc):Future[JsonNode]{.async.} =
  # defer: self.cleanUp()
  if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
  var sql = @[self.selectBuilder()][0]
  let firstItem = await getFirstItem(self, key, order)
  var quoteKey = key
  quote(quoteKey, self.driver)

  let where = if sql.contains("WHERE"): "AND" else: "WHERE"
  if order == Asc:
    sql = &"""
SELECT * FROM (
  {sql} {where} {quoteKey} < {id} ORDER BY {quoteKey} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {sql} {where} {quoteKey} >= {id} ORDER BY {quoteKey} ASC LIMIT {display+1}
) x
"""
  else:
    sql = &"""
SELECT * FROM (
  {sql} {where} {quoteKey} > {id} ORDER BY {quoteKey} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {sql} {where} {quoteKey} <= {id} ORDER BY {quoteKey} DESC LIMIT {display+1}
) x
"""
  self.placeHolder &= self.placeHolder
  self.log.logger(sql, self.placeHolder)
  var currentPage = await self.getAllRows(sql, self.placeHolder)
  if currentPage.len > 0:
    let newKey = if key.contains("."): key.split(".")[1] else: key
    # previous
    var previousId = currentPage[0][newKey].getInt()
    var hasPreviousId = true
    if previousId != firstItem:
      currentPage.delete(0)
    else:
      hasPreviousId = false
    # next
    var nextId = currentPage[currentPage.len-1][newKey].getInt()
    var hasNextId = true
    if currentPage.len > display:
      discard currentPage.pop()
    else:
      hasNextId = false

    return %*{
      "previousId": previousId,
      "hasPreviousId": hasPreviousId,
      "currentPage": currentPage,
      "nextId": nextId,
      "hasNextId": hasNextId
    }
  else:
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": 0,
      "hasNextId": false
    }


proc fastPaginateBack*(self:Rdb, display, id:int, key="id", order:Order=Asc):Future[JsonNode]{.async.} =
  # defer: self.cleanUp()
  if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
  var sql = @[self.selectBuilder()][0]
  let lastItem = await self.getLastItem(key, order)
  var quoteKey = key
  quote(quoteKey, self.driver)

  let where = if sql.contains("WHERE"): "AND" else: "WHERE"
  if order == Asc:
    sql = &"""
SELECT * FROM (
  {sql} {where} {quoteKey} > {id} ORDER BY {quoteKey} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {sql} {where} {quoteKey} <= {id} ORDER BY {quoteKey} DESC LIMIT {display+1}
) x
"""
  else:
    sql = &"""
SELECT * FROM (
  {sql} {where} {quoteKey} < {id} ORDER BY {quoteKey} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {sql} {where} {quoteKey} >= {id} ORDER BY {quoteKey} ASC LIMIT {display+1}
) x
"""
  self.placeHolder &= self.placeHolder
  self.log.logger(sql, self.placeHolder)
  var currentPage = await self.getAllRows(sql, self.placeHolder)
  if currentPage.len > 0:
    let newKey = if key.contains("."): key.split(".")[1] else: key
    # next
    let nextId = currentPage[0][newKey].getInt()
    var hasNextId = true
    if nextId != lastItem:
      currentPage.delete(0)
    else:
      hasNextId = false
    # previous
    let previousId = currentPage[currentPage.len-1][newKey].getInt
    var hasPreviousId = true
    if currentPage.len > display:
      discard currentPage.pop()
    else:
      hasPreviousId = false

    currentPage.reverse()

    return %*{
      "previousId": previousId,
      "hasPreviousId": hasPreviousId,
      "currentPage": currentPage,
      "nextId": nextId,
      "hasNextId": hasNextId
    }
  else:
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": 0,
      "hasNextId": false
    }
