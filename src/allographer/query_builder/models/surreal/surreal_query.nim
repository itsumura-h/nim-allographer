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


proc table*(self:SurrealQuery, tableArg: string): SurrealQuery =
  self.query["table"] = %tableArg
  return self


proc `distinct`*(self: SurrealQuery): SurrealQuery =
  self.query["distinct"] = %true
  return self

# # ============================== Conditions ==============================

# proc join*(self: SurrealQuery, table: string, column1: string, symbol: string,
#             column2: string): SurrealQuery =
#   if self.query.hasKey("join") == false:
#     self.query["join"] = %*[{
#       "table": table,
#       "column1": column1,
#       "symbol": symbol,
#       "column2": column2
#     }]
#   else:
#     self.query["join"].add(%*{
#       "table": table,
#       "column1": column1,
#       "symbol": symbol,
#       "column2": column2
#     })
#   return self


# proc leftJoin*(self: SurrealQuery, table: string, column1: string, symbol: string,
#               column2: string): SurrealQuery =
#   if self.query.hasKey("left_join") == false:
#     self.query["left_join"] = %*[{
#       "table": table,
#       "column1": column1,
#       "symbol": symbol,
#       "column2": column2
#     }]
#   else:
#     self.query["left_join"].add(%*{
#       "table": table,
#       "column1": column1,
#       "symbol": symbol,
#       "column2": column2
#     })
#   return self


## https://surrealdb.com/docs/surrealql/operators
const whereSymbols = ["is", "is not", "=", "!=", "<", "<=", ">=", ">", "<>", "CONTAINS", "CONTAINSNOT", "@@"]
const whereSymbolsError = """Arg position 3 is only allowed of ["is", "is not", "=", "!=", "<", "<=", ">=", ">", "<>", "CONTAINS", "CONTAINSNOT", "@@"]"""

proc where*(self: SurrealQuery, column: string, symbol: string,
            value: bool|int|float|string|SurrealId): SurrealQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("where") == false:
    self.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    self.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )
  return self


proc where*(self: SurrealQuery, column: string, symbol: string, value: nil.type): SurrealQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("where_null") == false:
    self.query["where_null"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    self.query["where_null"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )
  return self


proc orWhere*(self: SurrealQuery, column: string, symbol: string,
              value: bool|int|float|string|SurrealId): SurrealQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("or_where") == false:
    self.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    self.query["or_where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )
  return self


proc orWhere*(self: SurrealQuery, column: string, symbol: string, value: nil.type): SurrealQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("or_where") == false:
    self.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": nil
    }]
  else:
    self.query["or_where"].add(%*{
      "column": column,
      "symbol": symbol,
      "value": nil
    })
  return self


proc whereBetween*(self:SurrealQuery, column:string, width:array[2, int|float]): SurrealQuery =
  ## `rdb.table("user").whereBetween("index", [1, 3]).get()`
  ## 
  ## `SELECT * FROM user WHERE 1 <= index AND index <= 3`
  ## 
  ## https://surrealdb.com/docs/surrealql/operators#lessthanorequal
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


# proc whereBetween*(self:SurrealQuery, column:string, width:array[2, string]): SurrealQuery =
#   ## rdb.table("user").whereBetween("name", ["user1", "user3"]).get()
#   ## 
#   ## `SELECT * FROM user WHERE "user1" <= index <= "user3`
#   ## 
#   ## https://surrealdb.com/docs/surrealql/operators#lessthanorequal
#   if self.query.hasKey("where_between_string") == false:
#     self.query["where_between_string"] = %*[{
#       "column": column,
#       "width": width
#     }]
#   else:
#     self.query["where_between_string"].add(%*{
#       "column": column,
#       "width": width
#     })
#   return self


proc whereNotBetween*(self:SurrealQuery, column:string, width:array[2, int|float]): SurrealQuery =
  ## `rdb.table("user").whereNotBetween("index", [1, 3]).get()`
  ## 
  ## `SELECT * FROM user WHERE index > 1 AND 3 < index`
  ## 
  ## https://surrealdb.com/docs/surrealql/operators#greaterthan
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


# proc whereNotBetween*(self:SurrealQuery, column:string, width:array[2, string]): SurrealQuery =
#   self.placeHolder.add(%*{"key": column, "value": width[0]})
#   self.placeHolder.add(%*{"key": column, "value": width[1]})

#   if self.query.hasKey("where_not_between_string") == false:
#     self.query["where_not_between_string"] = %*[{
#       "column": column,
#       "width": width
#     }]
#   else:
#     self.query["where_not_between_string"].add(%*{
#       "column": column,
#       "width": width
#     })
#   return self


proc whereIn*(self:SurrealQuery, column:string, width:seq[int|float|string]): SurrealQuery =
  ## `rdb.table("user").whereIn("index", [2, 3]).get()`
  ## 
  ## `SELECT * FROM user WHERE [2, 3] CONTAINS index`
  ## 
  ## https://surrealdb.com/docs/surrealql/operators#contains
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


proc whereNotIn*(self:SurrealQuery, column:string, width:seq[int|float|string]): SurrealQuery =
  ## `rdb.table("user").whereNotIn("index", [2, 3]).get()`
  ## 
  ## `SELECT * FROM user WHERE [2, 3] CONTAINSNOT index`
  ## 
  ## https://surrealdb.com/docs/surrealql/operators#contains-not
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


proc whereNull*(self:SurrealQuery, column:string): SurrealQuery =
  ## https://surrealdb.com/docs/surrealql/operators#equal
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


proc groupBy*(self:SurrealQuery, column:string): SurrealQuery =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc having*(self: SurrealQuery, column: string, symbol: string,
              value: bool|int|float|string): SurrealQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("having") == false:
    self.query["having"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    self.query["having"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )
  return self


proc having*(self: SurrealQuery, column: string, symbol: string, value: nil.type): SurrealQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  if self.query.hasKey("having") == false:
    self.query["having"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": nil
    }]
  else:
    self.query["having"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": nil
      }
    )
  return self


proc fetch*(self:SurrealQuery, columnsArg: varargs[string]):SurrealQuery =
  self.query["fetch"] = %columnsArg
  return self


proc orderBy*(self:SurrealQuery, column:string, order:Order): SurrealQuery =
  if self.query.hasKey("order_by") == false:
    self.query["order_by"] = %*[{
      "column": column,
      "collation": "",
      "order": $order
    }]
  else:
    self.query["order_by"].add(%*{
      "column": column,
      "collation": "",
      "order": $order
    })
  return self


proc orderBy*(self:SurrealQuery, column:string, collation:Collation, order:Order): SurrealQuery =
  if self.query.hasKey("order_by") == false:
    self.query["order_by"] = %*[{
      "column": column,
      "collation": $collation,
      "order": $order
    }]
  else:
    self.query["order_by"].add(%*{
      "column": column,
      "collation": $collation,
      "order": $order
    })
  return self


proc limit*(self: SurrealQuery, num: int): SurrealQuery =
  self.query["limit"] = %num
  return self


proc start*(self: SurrealQuery, num: int): SurrealQuery =
  self.query["start"] = %num
  return self


proc parallel*(self: SurrealQuery): SurrealQuery =
  self.query["parallel"] = %true
  return self



# proc offset*(self: SurrealQuery, num: int): SurrealQuery =
#   self.query["offset"] = %num
#   return self


# proc inTransaction*(self:SurrealQuery, connI:int) =
#   ## Only used in transation block
#   self.isInTransaction = true
#   self.transactionConn = connI


# proc freeTransactionConn*(self:SurrealQuery, connI:int) =
#   ## Only used in transation block
#   self.isInTransaction = false


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:SurrealConnections | SurrealQuery | RawSurrealQuery):Future[int] {.async.} =
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


proc returnConn(self:SurrealConnections | SurrealQuery | RawSurrealQuery, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools[i].isBusy = false


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
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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

  let rows = surreal_impl.query(self.pools[connI].conn, queryString, self.placeHolder, self.timeout).await
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

  surreal_impl.exec(self.pools[connI].conn, queryString, self.placeHolder, self.timeout).await


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
#   let (columns, _) = surreal_impl.query(self.pools[connI].conn, columnGetQuery, newJArray(), self.timeout).await

#   let (rows, _) = surreal_impl.execGetValue(self.pools[connI].conn, queryString, self.placeHolder, columns, self.timeout).await
#   return rows[0][0]


proc getAllRows(self:RawSurrealQuery, queryString:string):Future[seq[JsonNode]] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  var strArgs:seq[string]
  for arg in self.placeHolder.items:
    case arg.kind
    of JBool:
      strArgs.add($arg.getBool)
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

  let rows = surreal_impl.query(
    self.pools[connI].conn,
    queryString,
    strArgs,
    self.timeout
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
#     self.pools[connI].conn,
#     queryString,
#     self.placeHolder,
#     self.timeout
#   ).await
  
#   return rows


proc getRow(self:RawSurrealQuery, queryString:string):Future[Option[JsonNode]] {.async.} =
  var connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  let rows = surreal_impl.query(self.pools[connI].conn, queryString, self.placeHolder, self.timeout).await
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
#     self.pools[connI].conn,
#     queryString,
#     self.placeHolder,
#     self.timeout
#   ).await
#   return rows[0]


proc exec(self:RawSurrealQuery, queryString:string) {.async.} =
  let connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  surreal_impl.exec(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
  ).await


proc info(self:RawSurrealQuery, queryString:string):Future[JsonNode] {.async.} =
  let connI = getFreeConn(self).await
  defer:
    self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  return surreal_impl.info(
    self.pools[connI].conn,
    queryString,
    self.placeHolder,
    self.timeout
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

  return surreal_impl.info(self.pools[connI].conn, queryString, strArgs, self.timeout).await


# proc transactionStart(self:SurrealConnections) {.async.} =
#   let connI = getFreeConn(self).await
#   if connI == errorConnectionNum:
#     return
#   self.isInTransaction = true
#   self.transactionConn = connI

#   surreal_impl.exec(self.pools[connI].conn, "BEGIN", newJArray(), newSeq[Row](), self.timeout).await


# proc transactionEnd(self:SurrealConnections, query:string) {.async.} =
#   defer:
#     self.returnConn(self.transactionConn).await
#     self.transactionConn = 0
#     self.isInTransaction = false

#   surreal_impl.exec(self.pools[self.transactionConn].conn, query, newJArray(), newSeq[Row](), self.timeout).await


# ================================================================================
# public exec
# ================================================================================

proc get*(self: SurrealQuery):Future[seq[JsonNode]] {.async.} =
  ## https://surrealdb.com/docs/surrealql/statements/select
  let sql = self.selectBuilder()
  try:
    self.log.logger(sql)
    return self.getAllRows(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return newSeq[JsonNode]()


proc first*(self: SurrealQuery):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFirstBuilder()
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    return none(JsonNode)


proc find*(self: SurrealQuery, id:SurrealId, key="id"):Future[Option[JsonNode]] {.async.} =
  var sql = self.selectFindBuilder(id, key)
  sql = questionToDaller(sql)
  try:
    self.log.logger(sql)
    return self.getRow(sql).await
  except Exception:
    self.log.echoErrorMsg(sql)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )
    raise getCurrentException()


# proc getPlain*(self:SurrealQuery):Future[seq[seq[string]]] {.async.} =
#   var sql = self.selectBuilder()
#   sql = questionToDaller(sql)
#   try:
#     self.log.logger(sql)
#     return self.getAllRowsPlain(sql, self.placeHolder).await
#   except Exception:
#     self.log.echoErrorMsg(sql)
#     self.log.echoErrorMsg( getCurrentExceptionMsg() )
#     raise getCurrentException()


# proc firstPlain*(self:SurrealQuery):Future[seq[string]] {.async.} =
#   var sql = self.selectFirstBuilder()
#   sql = questionToDaller(sql)
#   try:
#     self.log.logger(sql)
#     return self.getRowPlain(sql, self.placeHolder).await
#   except Exception:
#     self.log.echoErrorMsg(sql)
#     self.log.echoErrorMsg( getCurrentExceptionMsg() )
#     raise getCurrentException()


# proc findPlain*(self:SurrealQuery, id: string, key="id"):Future[seq[string]] {.async.} =
#   self.placeHolder.add(%*{"key":key, "value":id})
#   var sql = self.selectFindBuilder(key)
#   sql = questionToDaller(sql)
#   try:
#     self.log.logger(sql)
#     return self.getRowPlain(sql, self.placeHolder).await
#   except Exception:
#     self.log.echoErrorMsg(sql)
#     self.log.echoErrorMsg( getCurrentExceptionMsg() )
#     raise getCurrentException()


# proc findPlain*(self:SurrealQuery, id: int, key="id"):Future[seq[string]] {.async.} =
#   return self.findPlain($id, key).await


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
    self.timeout,
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
  self.placeHolder.add(%id)
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
  except Exception:
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


# proc min*(self:SurrealQuery, column:string):Future[Option[string]] {.async.} =
#   var sql = self.minBuilder(column)
#   sql = questionToDaller(sql)
#   self.log.logger(sql)
#   let response =  self.getRow(sql).await
#   if response.isSome:
#     case response.get["aggregate"].kind
#     of JInt:
#       return some($(response.get["aggregate"].getInt))
#     of JFloat:
#       return some($(response.get["aggregate"].getFloat))
#     else:
#       return some(response.get["aggregate"].getStr)
#   else:
#     return none(string)


proc max*(self:SurrealQuery, column:string, collaction:Collation=None):Future[int]{.async.} =
  ## = `ORDER BY {column} {collaction} DESC LIMIT 1`
  let self = self.orderBy(column, collaction, Desc).limit(1)
  let sql = self.selectFirstBuilder()
  self.log.logger(sql)
  let response =  self.getRow(sql).await
  if response.isSome:
    let column = if column.contains("."): column.split(".")[^1] else: column
    return response.get[column].getInt()
  else:
    return 0


# proc avg*(self:SurrealQuery, column:string):Future[Option[float]]{.async.} =
#   var sql = self.avgBuilder(column)
#   sql = questionToDaller(sql)
#   self.log.logger(sql)
#   let response =  await self.getRow(sql)
#   if response.isSome:
#     return response.get["aggregate"].getFloat().some
#   else:
#     return none(float)


# proc sum*(self:SurrealQuery, column:string):Future[Option[float]]{.async.} =
#   var sql = self.sumBuilder(column)
#   sql = questionToDaller(sql)
#   self.log.logger(sql)
#   let response = await self.getRow(sql)
#   if response.isSome:
#     return response.get["aggregate"].getFloat().some
#   else:
#     return none(float)


# proc begin*(self:SurrealConnections) {.async.} =
#   self.log.logger("BEGIN")
#   self.transactionStart().await


# proc rollback*(self:SurrealConnections) {.async.} =
#   self.log.logger("ROLLBACK")
#   self.transactionEnd("ROLLBACK").await


# proc commit*(self:SurrealConnections, connI:int) {.async.} =
#   self.log.logger("COMMIT")
#   self.transactionEnd("COMMIT").await


proc get*(self: RawSurrealQuery):Future[seq[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getAllRows(self.queryString).await


# proc getPlain*(self: RawSurrealQuery):Future[seq[seq[string]]] {.async.} =
#   ## It is only used with raw()
#   self.log.logger(self.queryString)
#   return self.getAllRowsPlain(self.queryString, self.placeHolder).await


proc exec*(self: RawSurrealQuery) {.async.} =
  ## It is only used with raw()
  ## 
  ## https://surrealdb.com/docs/integration/http#sql
  ## 
  ## https://surrealdb.com/docs/surrealql
  self.log.logger(self.queryString)
  self.exec(self.queryString).await
  try:
    self.log.logger(self.queryString)
    self.exec(self.queryString).await
  except Exception:
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
  except Exception:
    self.log.echoErrorMsg(self.queryString)
    self.log.echoErrorMsg( getCurrentExceptionMsg() )



proc first*(self: RawSurrealQuery):Future[Option[JsonNode]] {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  return self.getRow(self.queryString).await


# proc firstPlain*(self: RawSurrealQuery):Future[seq[string]] {.async.} =
#   ## It is only used with raw()
#   self.log.logger(self.queryString)
#   return self.getRowPlain(self.queryString, self.placeHolder).await


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
