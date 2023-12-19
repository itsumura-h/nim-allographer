import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../libs/postgres/postgres_lib
import ../../libs/postgres/postgres_impl
import ../../log
import ../../enums
import ../database_types
import ./query/postgres_builder
import ./postgres_types


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:PostgresConnections | PostgresQuery | RawPostgresQuery):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.conns.len:
      if not self.pools.conns[i].isBusy:
        self.pools.conns[i].isBusy = true
        echo "=== getFreeConn ", i
        return i
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.pools.timeout:
      return errorConnectionNum


proc returnConn(self:PostgresConnections | PostgresQuery | RawPostgresQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools.conns[i].isBusy = false


# ================================================================================
# query
# ================================================================================


proc select*(self:PostgresConnections, columnsArg:varargs[string]):PostgresQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let postgresQuery = PostgresQuery(
    log: self.log,
    pools: self.pools,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return postgresQuery


proc table*(self:PostgresConnections, tableArg: string): PostgresQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let postgresQuery = PostgresQuery(
    log: self.log,
    pools: self.pools,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return postgresQuery


proc table*(self:PostgresQuery, tableArg: string): PostgresQuery =
  self.query["table"] = %tableArg
  return self


proc `distinct`*(self: PostgresQuery): PostgresQuery =
  self.query["distinct"] = %true
  return self

# ============================== Conditions ==============================

proc join*(self: PostgresQuery, table: string, column1: string, symbol: string,
            column2: string): PostgresQuery =
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


proc leftJoin*(self: PostgresQuery, table: string, column1: string, symbol: string,
              column2: string): PostgresQuery =
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

proc where*(self: PostgresQuery, column: string, symbol: string,
            value: string|int|float): PostgresQuery =
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


proc where*(self: PostgresQuery, column: string, symbol: string,
            value: bool): PostgresQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

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


proc where*(self: PostgresQuery, column: string, symbol: string, value: nil.type): PostgresQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("where_null") == false:
    self.query["where_null"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "null"
    }]
  else:
    self.query["where_null"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "null"
      }
    )
  return self


proc orWhere*(self: PostgresQuery, column: string, symbol: string,
              value: string|int|float|bool): PostgresQuery =
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


proc orWhere*(self: PostgresQuery, column: string, symbol: string, value: nil.type): PostgresQuery =
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


proc whereBetween*(self:PostgresQuery, column:string, width:array[2, int|float]): PostgresQuery =
  self.placeHolder.add(%*{"key": column, "value": width[0]})
  self.placeHolder.add(%*{"key": column, "value": width[1]})

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


proc whereBetween*(self:PostgresQuery, column:string, width:array[2, string]): PostgresQuery =
  self.placeHolder.add(%*{"key": column, "value": width[0]})
  self.placeHolder.add(%*{"key": column, "value": width[1]})

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


proc whereNotBetween*(self:PostgresQuery, column:string, width:array[2, int|float]): PostgresQuery =
  self.placeHolder.add(%*{"key": column, "value": width[0]})
  self.placeHolder.add(%*{"key": column, "value": width[1]})

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


proc whereNotBetween*(self:PostgresQuery, column:string, width:array[2, string]): PostgresQuery =
  self.placeHolder.add(%*{"key": column, "value": width[0]})
  self.placeHolder.add(%*{"key": column, "value": width[1]})

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


proc whereIn*(self:PostgresQuery, column:string, width:seq[int|float|string]): PostgresQuery =
  for row in width:
    self.placeHolder.add(%*{"key": column, "value": row})

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


proc whereNotIn*(self:PostgresQuery, column:string, width:seq[int|float|string]): PostgresQuery =
  for row in width:
    self.placeHolder.add(%*{"key": column, "value": row})

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


proc whereNull*(self:PostgresQuery, column:string): PostgresQuery =
  if self.query.hasKey("where_null") == false:
    self.query["where_null"] = %*[{
      "column": column,
      "symbol": "is",
    }]
  else:
    self.query["where_null"].add(%*{
      "column": column,
      "symbol": "is",
    })
  return self


proc groupBy*(self:PostgresQuery, column:string): PostgresQuery =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc having*(self: PostgresQuery, column: string, symbol: string,
              value: string|int|float|bool): PostgresQuery =
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

proc having*(self: PostgresQuery, column: string, symbol: string, value: nil.type): PostgresQuery =
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


proc orderBy*(self:PostgresQuery, column:string, order:Order): PostgresQuery =
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


proc limit*(self: PostgresQuery, num: int): PostgresQuery =
  self.query["limit"] = %num
  return self


proc offset*(self: PostgresQuery, num: int): PostgresQuery =
  self.query["offset"] = %num
  return self


proc raw*(self:PostgresConnections, sql:string, arges=newJArray()): RawPostgresQuery =
  ## arges is `JArray`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawPostgresQuery(
    log: self.log,
    pools: self.pools,
    query: newJObject(),
    queryString: sql,
    placeHolder: arges,
    isInTransaction: false,
    transactionConn: 0
  )
  return rawQueryRdb


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

  sleepAsync(0).await

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

  let table = self.query["table"].getStr
  let columnGetQuery = &"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'"
  let (columns, _) = postgres_impl.query(self.pools.conns[connI].conn, columnGetQuery, newJArray(), self.pools.timeout).await

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

  let table = self.query["table"].getStr
  let columnGetQuery = &"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'"
  let (columns, _) = postgres_impl.query(self.pools.conns[connI].conn, columnGetQuery, newJArray(), self.pools.timeout).await

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

  postgres_impl.exec(self.pools.conns[connI].conn, "BEGIN", newJArray(), newSeq[Row](), self.pools.timeout).await


proc transactionEnd(self:PostgresConnections|PostgresQuery, query:string) {.async.} =
  postgres_impl.exec(self.pools.conns[self.transactionConn].conn, query, newJArray(), newSeq[Row](), self.pools.timeout).await
  self.returnConn(self.transactionConn).await
  self.transactionConn = 0
  self.isInTransaction = false


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


# ==================== return Object ====================
proc get*[T](self: PostgresQuery, typ:typedesc[T]):Future[seq[T]] {.async.} =
  var sql = self.selectBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    let rows = self.getAllRows(sql).await
    for row in rows:
      result.add(row.to(typ))
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc first*[T](self: PostgresQuery, typ:typedesc[T]):Future[Option[T]] {.async.} =
  var sql = self.selectFirstBuilder()
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    let row = self.getRow(sql).await
    if row.isSome():
      return row.get().to(typ).some()
    else:
      return none(typ)
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*[T](self: PostgresQuery, id:string, typ:typedesc[T], key="id"):Future[Option[T]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value": id})
  var sql = self.selectFindBuilder(key)
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    let row = self.getRow(sql).await
    if row.isSome():
      return row.get().to(typ).some()
    else:
      return none(typ)
  except CatchableError:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*[T](self: PostgresQuery, id:int, typ:typedesc[T], key="id"):Future[Option[T]] {.async.} =
  return self.find($id, typ, key).await


# ==================== insert ====================
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


proc update*(self: PostgresQuery, items: JsonNode){.async.} =
  var sql = self.updateBuilder(items)
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


proc begin*(self:PostgresQuery) {.async.} =
  self.log.logger("BEGIN")
  self.transactionStart().await


proc rollback*(self:PostgresQuery) {.async.} =
  self.log.logger("ROLLBACK")
  self.transactionEnd("ROLLBACK").await


proc commit*(self:PostgresQuery) {.async.} =
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


template seeder*(rdb:PostgresConnections, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table is empty.
  block:
    if rdb.table(tableName).count().waitFor == 0:
      body


template seeder*(rdb:PostgresConnections, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  block:
    if rdb.table(tableName).select(column).count().waitFor == 0:
      body
