import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../libs/mysql/mysql_impl
import ../../log
import ../../enums
import ../database_types
import ./query/mysql_builder
import ./mysql_types


proc table*(self:MysqlQuery, tableArg: string): MysqlQuery =
  self.query["table"] = %tableArg
  return self


proc `distinct`*(self: MysqlQuery): MysqlQuery =
  self.query["distinct"] = %true
  return self

# ============================== Conditions ==============================

proc join*(self: MysqlQuery, table: string, column1: string, symbol: string,
            column2: string): MysqlQuery =
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


proc leftJoin*(self: MysqlQuery, table: string, column1: string, symbol: string,
              column2: string): MysqlQuery =
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

proc where*(self: MysqlQuery, column: string, symbol: string,
            value: string|int|float): MysqlQuery =
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


proc where*(self: MysqlQuery, column: string, symbol: string,
            value: bool): MysqlQuery =
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


proc where*(self: MysqlQuery, column: string, symbol: string, value: nil.type): MysqlQuery =
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


proc orWhere*(self: MysqlQuery, column: string, symbol: string,
              value: string|int|float|bool): MysqlQuery =
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


proc orWhere*(self: MysqlQuery, column: string, symbol: string, value: nil.type): MysqlQuery =
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


proc whereBetween*(self:MysqlQuery, column:string, width:array[2, int|float]): MysqlQuery =
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


proc whereBetween*(self:MysqlQuery, column:string, width:array[2, string]): MysqlQuery =
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


proc whereNotBetween*(self:MysqlQuery, column:string, width:array[2, int|float]): MysqlQuery =
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


proc whereNotBetween*(self:MysqlQuery, column:string, width:array[2, string]): MysqlQuery =
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


proc whereIn*(self:MysqlQuery, column:string, width:seq[int|float|string]): MysqlQuery =
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


proc whereNotIn*(self:MysqlQuery, column:string, width:seq[int|float|string]): MysqlQuery =
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


proc whereNull*(self:MysqlQuery, column:string): MysqlQuery =
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


proc groupBy*(self:MysqlQuery, column:string): MysqlQuery =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc having*(self: MysqlQuery, column: string, symbol: string,
              value: string|int|float|bool): MysqlQuery =
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

proc having*(self: MysqlQuery, column: string, symbol: string, value: nil.type): MysqlQuery =
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


proc orderBy*(self:MysqlQuery, column:string, order:Order): MysqlQuery =
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


proc limit*(self: MysqlQuery, num: int): MysqlQuery =
  self.query["limit"] = %num
  return self


proc offset*(self: MysqlQuery, num: int): MysqlQuery =
  self.query["offset"] = %num
  return self


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:MysqlConnections | MysqlQuery | RawMysqlQuery):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.len:
      if not self.pools[i].isBusy:
        self.pools[i].isBusy = true
        return i
        break
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.timeout:
      return errorConnectionNum


proc returnConn(self:MysqlConnections | MysqlQuery | RawMysqlQuery, i: int) {.async.} =
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
    return

  let (rows, dbRows) = mysql_impl.query(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  let (rows, _) = mysql_impl.query(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  let (rows, dbRows) = mysql_impl.query(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return
  
  let (rows, _) = mysql_impl.query(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  let database = self.info.database
  let table = self.query["table"].getStr
  let columns = mysql_impl.getColumnTypes(self.pools[connI].conn, $database, table, self.timeout).await
  mysql_impl.exec(self.pools[connI].conn, queryString, self.placeHolder, columns, self.timeout).await


# proc insertId(self:MysqlQuery, queryString:string, key:string):Future[string] {.async.} =
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
#   let (columns, _) = mysql_impl.query(self.pools[connI].conn, columnGetQuery, newJArray(), self.timeout).await

#   let (rows, _) = mysql_impl.execGetValue(self.pools[connI].conn, queryString, self.placeHolder, columns, self.timeout).await
#   return rows[0][0]


proc getAllRows(self:RawMysqlQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let (rows, dbRows) = mysql_impl.rawQuery(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  let (rows, _) = mysql_impl.rawQuery(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  let (rows, dbRows) = mysql_impl.rawQuery(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  let (rows, _) = mysql_impl.rawQuery(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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
    return

  mysql_impl.exec(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
  ).await


proc getColumns(self:MysqlQuery, queryString:string):Future[seq[string]] {.async.} =
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

  return mysql_impl.getColumns(self.pools[connI].conn, queryString, strArgs, self.timeout).await


proc transactionStart(self:MysqlConnections) {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  self.isInTransaction = true
  self.transactionConn = connI

  mysql_impl.exec(self.pools[connI].conn, "BEGIN", newJArray(), newSeq[Row](), self.timeout).await


proc transactionEnd(self:MysqlConnections, query:string) {.async.} =
  defer:
    self.returnConn(self.transactionConn).await
    self.transactionConn = 0
    self.isInTransaction = false

  mysql_impl.exec(self.pools[self.transactionConn].conn, query, newJArray(), newSeq[Row](), self.timeout).await


# ================================================================================
# public exec
# ================================================================================

proc get*(self: MysqlQuery):Future[seq[JsonNode]] {.async.} =
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc first*(self: MysqlQuery):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc find*(self: MysqlQuery, id:string, key="id"):Future[Option[JsonNode]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value": id})
  var sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except Exception:
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
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc firstPlain*(self:MysqlQuery):Future[seq[string]] {.async.} =
  var sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:MysqlQuery, id: string, key="id"):Future[seq[string]] {.async.} =
  self.placeHolder.add(%*{"key":key, "value":id})
  var sql = self.selectFindBuilder(key)
  try:
    self.log.logger(sql)
    return self.getRowPlain(sql, self.placeHolder).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


proc findPlain*(self:MysqlQuery, id: int, key="id"):Future[seq[string]] {.async.} =
  return self.findPlain($id, key).await


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
  self.log.logger(sql)
  self.exec(sql).await
  let resp = self.getRow(&"SELECT LAST_INSERT_ID() as '{key}'").await
  if resp.isSome:
    let row = resp.get()
    if row[key].kind == JInt:
      return $row[key].getInt
    else:
      return row[key].getStr
  else:
    return ""


proc insertId*(self: MysqlQuery, items: seq[JsonNode], key="id"):Future[seq[string]] {.async.} =
  result = newSeq[string](items.len)
  for i, item in items:
    var sql = self.insertValueBuilder(item)
    self.log.logger(sql)
    self.exec(sql).await
    let resp = self.getRow(&"SELECT LAST_INSERT_ID() as '{key}'").await
    if resp.isSome:
      let row = resp.get()
      if row[key].kind == JInt:
        result[i] = $row[key].getInt
      else:
        result[i] = row[key].getStr
    else:
      result[i] = ""
    self.placeHolder = newJArray()


proc update*(self: MysqlQuery, items: JsonNode){.async.} =
  var sql = self.updateBuilder(items)
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
  except Exception:
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
