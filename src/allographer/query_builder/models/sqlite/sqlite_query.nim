import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../libs/sqlite/sqlite_impl
import ../../log
import ../../enums
import ../database_types
import ./query/sqlite_builder
import ./sqlite_types


proc table*(self:SqliteQuery, tableArg: string): SqliteQuery =
  self.query["table"] = %tableArg
  return self


proc `distinct`*(self: SqliteQuery): SqliteQuery =
  self.query["distinct"] = %true
  return self

# ============================== Conditions ==============================

proc join*(self: SqliteQuery, table: string, column1: string, symbol: string,
            column2: string): SqliteQuery =
  if self.query.hasKey("join") == false:
    self.query["join"] = %*[{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    }]
  else:
    self.query["join"].add(%*{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    })
  return self


proc leftJoin*(self: SqliteQuery, table: string, column1: string, symbol: string,
              column2: string): SqliteQuery =
  if self.query.hasKey("left_join") == false:
    self.query["left_join"] = %*[{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    }]
  else:
    self.query["left_join"].add(%*{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    })
  return self


const whereSymbols = ["is", "is not", "=", "!=", "<", "<=", ">=", ">", "<>", "LIKE","%LIKE","LIKE%","%LIKE%"]
const whereSymbolsError = """Arg position 3 is only allowed of ["is", "is not", "=", "!=", "<", "<=", ">=", ">", "<>", "LIKE","%LIKE","LIKE%","%LIKE%"]"""

proc where*(self: SqliteQuery, column: string, symbol: string,
            value: string|int|float): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  self.placeHolder.add(%*{"key": column, "value": value})

  if self.query.hasKey("where") == false:
    self.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    self.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )
  return self


proc where*(self: SqliteQuery, column: string, symbol: string,
            value: bool): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  let val = if value: 1 else: 0
  self.placeHolder.add(%*{"key":column, "value":value})

  if self.query.hasKey("where") == false:
    self.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    self.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )
  return self


proc where*(self: SqliteQuery, column: string, symbol: string, value: nil.type): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("where") == false:
    self.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "null"
    }]
  else:
    self.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "null"
      }
    )
  return self


proc orWhere*(self: SqliteQuery, column: string, symbol: string,
              value: string|int|float|bool): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  self.placeHolder.add(%*{"key":column, "value":value})

  if self.query.hasKey("or_where") == false:
    self.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    self.query["or_where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )
  return self

proc orWhere*(self: SqliteQuery, column: string, symbol: string, value: nil.type): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("or_where") == false:
    self.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "null"
    }]
  else:
    self.query["or_where"].add(%*{
      "column": column,
      "symbol": symbol,
      "value": "null"
    })
  return self

proc whereBetween*(self:SqliteQuery, column:string, width:array[2, int|float]): SqliteQuery =
  if self.query.hasKey("where_between") == false:
    self.query["where_between"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    self.query["where_between"].add(%*{
      "column": column,
      "width": width
    })
  return self

proc whereBetween*(self:SqliteQuery, column:string, width:array[2, string]): SqliteQuery =
  if self.query.hasKey("where_between_string") == false:
    self.query["where_between_string"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    self.query["where_between_string"].add(%*{
      "column": column,
      "width": width
    })
  return self

proc whereNotBetween*(self:SqliteQuery, column:string, width:array[2, int|float]): SqliteQuery =
  if self.query.hasKey("where_not_between") == false:
    self.query["where_not_between"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    self.query["where_not_between"].add(%*{
      "column": column,
      "width": width
    })
  return self

proc whereNotBetween*(self:SqliteQuery, column:string, width:array[2, string]): SqliteQuery =
  if self.query.hasKey("where_not_between_string") == false:
    self.query["where_not_between_string"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    self.query["where_not_between_string"].add(%*{
      "column": column,
      "width": width
    })
  return self

proc whereIn*(self:SqliteQuery, column:string, width:seq[int|float|string]): SqliteQuery =
  if self.query.hasKey("where_in") == false:
    self.query["where_in"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    self.query["where_in"].add(%*{
      "column": column,
      "width": width
    })
  return self


proc whereNotIn*(self:SqliteQuery, column:string, width:seq[int|float|string]): SqliteQuery =
  if self.query.hasKey("where_not_in") == false:
    self.query["where_not_in"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    self.query["where_not_in"].add(%*{
      "column": column,
      "width": width
    })
  return self


proc whereNull*(self:SqliteQuery, column:string): SqliteQuery =
  if self.query.hasKey("where_null") == false:
    self.query["where_null"] = %*[{
      "column": column
    }]
  else:
    self.query["where_null"].add(%*{
      "column": column
    })
  return self


proc groupBy*(self:SqliteQuery, column:string): SqliteQuery =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc having*(self: SqliteQuery, column: string, symbol: string,
              value: string|int|float|bool): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  self.placeHolder.add(%*{"key":column, "value":value})

  if self.query.hasKey("having") == false:
    self.query["having"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    self.query["having"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )
  return self

proc having*(self: SqliteQuery, column: string, symbol: string, value: nil.type): SqliteQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("having") == false:
    self.query["having"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "null"
    }]
  else:
    self.query["having"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "null"
      }
    )
  return self


proc orderBy*(self:SqliteQuery, column:string, order:Order): SqliteQuery =
  if self.query.hasKey("order_by") == false:
    self.query["order_by"] = %*[{
      "column": column,
      "order": $order
    }]
  else:
    self.query["order_by"].add(%*{
      "column": column,
      "order": $order
    })
  return self


proc limit*(self: SqliteQuery, num: int): SqliteQuery =
  self.query["limit"] = %num
  return self


proc offset*(self: SqliteQuery, num: int): SqliteQuery =
  self.query["offset"] = %num
  return self


proc inTransaction*(self:SqliteQuery, connI:int) =
  ## Only used in transation block
  self.isInTransaction = true
  self.transactionConn = connI


proc freeTransactionConn*(self:SqliteQuery, connI:int) =
  ## Only used in transation block
  self.isInTransaction = false


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:SqliteConnections | SqliteQuery | RawSqliteQuery):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.len:
      if not self.pools[i].isBusy:
        self.pools[i].isBusy = true
        # echo "=== getFreeConn ", i
        return i
        break
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.timeout:
      return errorConnectionNum


proc returnConn(self: SqliteConnections | SqliteQuery | RawSqliteQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools[i].isBusy = false


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

proc getAllRows(self:SqliteQuery|RawSqliteQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
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

  let (rows, dbRows) = sqlite_impl.query(self.pools[connI].conn, queryString, strArgs, self.timeout).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return newSeq[JsonNode](0)
  return toJson(rows, dbRows) # seq[JsonNode]



proc getRow(self:SqliteQuery|RawSqliteQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
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
  
  let (rows, dbRows) = sqlite_impl.query(self.pools[connI].conn, queryString, strArgs, self.timeout).await

  if rows.len == 0:
    self.log.echoErrorMsg(queryString)
    return none(JsonNode)
  return toJson(rows, dbRows)[0].some


proc getAllRowsPlain(self:SqliteQuery|RawSqliteQuery, queryString:string, args:JsonNode):Future[seq[seq[string]]] {.async.} =
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

  let (rows, _) = sqlite_impl.query(self.pools[connI].conn, queryString, strArgs, self.timeout).await
  return rows


proc getRowPlain(self:SqliteQuery|RawSqliteQuery, queryString:string, args:JsonNode):Future[seq[string]] {.async.} =
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
  
  let (rows, _) = sqlite_impl.query(self.pools[connI].conn, queryString, strArgs, self.timeout).await
  return rows[0]


proc exec(self:SqliteQuery, queryString:string, args=newJArray()) {.async.} =
  ## args is `JArray`
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
  let columns = sqlite_impl.getColumnTypes(self.pools[connI].conn, columnGetQuery).await

  sqlite_impl.exec(self.pools[connI].conn, queryString, self.placeHolder, columns, self.timeout).await


proc exec(self:RawSqliteQuery, queryString:string, args:JsonNode) {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  sqlite_impl.exec(self.pools[connI].conn, queryString, args, self.timeout).await


proc insertId(self:SqliteQuery, queryString:string, key:string):Future[int]{.async.} =
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
  let columns = sqlite_impl.getColumnTypes(self.pools[connI].conn, columnGetQuery).await

  sqlite_impl.exec(self.pools[connI].conn, queryString, self.placeHolder, columns, self.timeout).await

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

  let (rows, _) = sqlite_impl.query(self.pools[connI].conn, "SELECT last_insert_rowid()", strArgs, self.timeout).await
  return rows[0][0].parseInt



# proc getAllRows(self:RawSqliteQuery, queryString:string, args:JsonNode):Future[seq[JsonNode]] {.async.} =
#   var connI = self.transactionConn
#   if not self.isInTransaction:
#     connI = getFreeConn(self).await
#   defer:
#     if not self.isInTransaction:
#       self.returnConn(connI).await
#   if connI == errorConnectionNum:
#     return

#   var strArgs:seq[string]
#   for arg in args.items:
#     case arg["value"].kind
#     of JBool:
#       if arg["value"].getBool:
#         strArgs.add("1")
#       else:
#         strArgs.add("0")
#     of JInt:
#       strArgs.add($arg["value"].getInt)
#     of JFloat:
#       strArgs.add($arg["value"].getFloat)
#     of JString:
#       strArgs.add($arg["value"].getStr)
#     of JNull:
#       strArgs.add("NULL")
#     else:
#       strArgs.add(arg["value"].pretty)

#   let (rows, dbRows) = sqlite_impl.query(self.pools[connI].conn, queryString, strArgs, self.timeout).await

#   if rows.len == 0:
#     self.log.echoErrorMsg(queryString)
#     return newSeq[JsonNode](0)
#   return toJson(rows, dbRows) # seq[JsonNode]



# proc exec(self:SqliteQuery, queryString:string, args:seq[string]) {.async.} =
#   var connI = self.transactionConn
#   if not self.isInTransaction:
#     connI = getFreeConn(self).await
#   defer:
#     if not self.isInTransaction:
#       self.returnConn(connI).await
#   if connI == errorConnectionNum:
#     return

#   sqlite_impl.exec(self.pools[connI].conn, queryString, self.placeHolder, self.timeout).await


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

  return sqlite_impl.getColumns(self.pools[connI].conn, queryString, strArgs, self.timeout).await


proc transactionStart(self:SqliteConnections) {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  self.isInTransaction = true
  self.transactionConn = connI
  sqlite_impl.exec(self.pools[connI].conn, "BEGIN", newJArray(), self.timeout).await


proc transactionEnd(self:SqliteConnections, query:string) {.async.} =
  defer:
    self.returnConn(self.transactionConn).await
    self.transactionConn = 0
    self.isInTransaction = false

  sqlite_impl.exec(self.pools[self.transactionConn].conn, query, newJArray(), self.timeout).await


# ================================================================================
# public exec
# ================================================================================

proc get*(self:SqliteQuery):Future[seq[JsonNode]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc first*(self:SqliteQuery):Future[Option[JsonNode]] {.async.} =
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self:SqliteQuery, id: string, key="id"):Future[Option[JsonNode]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self:SqliteQuery, id:int, key="id"):Future[Option[JsonNode]]{.async.} =
  return self.find($id, key).await


proc getPlain*(self:SqliteQuery):Future[seq[seq[string]]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRowsPlain(sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc firstPlain*(self:SqliteQuery):Future[seq[string]] {.async.} =
  let sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:SqliteQuery, id: string, key="id"):Future[seq[string]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  let sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:SqliteQuery, id: int, key="id"):Future[seq[string]] {.async.} =
  return self.findPlain($id, key).await


proc insert*(self:SqliteQuery, items:JsonNode) {.async.} =
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  self.exec(sql, items).await


proc insert*(self:SqliteQuery, items:seq[JsonNode]) {.async.} =
  let sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  self.exec(sql, self.placeHolder).await


proc insertId*(self: SqliteQuery, items: JsonNode, key="id"):Future[int] {.async.} =
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  return self.insertId(sql, key).await


proc insertId*(self: SqliteQuery, items: seq[JsonNode], key="id"):Future[int] {.async.} =
  let sql = self.insertValuesBuilder(items)
  self.log.logger(sql)
  result = self.insertId(sql, key).await
  self.placeHolder = newJArray()


proc insertsId*(self: SqliteQuery, items: seq[JsonNode], key="id"):Future[seq[int]]{.async.} =
  var response = newSeq[int](items.len)
  for i, row in items:
    # row is JObject
    let sql = self.insertValueBuilder(row)
    self.log.logger(sql)
    response[i] = self.insertId(sql, key).await
    self.placeHolder = newJArray()
  return response


proc update*(self:SqliteQuery, items:JsonNode) {.async.} =
  let sql = self.updateBuilder(items)
  self.log.logger(sql)
  self.exec(sql, items).await


proc delete*(self:SqliteQuery) {.async.} =
  let sql = self.deleteBuilder()
  self.log.logger(sql)
  self.exec(sql).await


proc delete*(self:SqliteQuery, id:int, key="id") {.async.} =
  let sql = self.deleteByIdBuilder(id, key)
  self.log.logger(sql)
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


proc commit*(self:SqliteConnections, connI:int) {.async.} =
  self.log.logger("COMMIT")
  self.transactionEnd("COMMIT").await


proc exec*(self: RawSqliteQuery) {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  self.exec(self.queryString, self.placeHolder).await


proc get*(self: RawSqliteQuery):Future[seq[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRows(self.queryString).await


proc getPlain*(self: RawSqliteQuery):Future[seq[seq[string]]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRowsPlain(self.queryString, self.placeHolder).await


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
