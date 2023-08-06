import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import std/times
import ../../libs/postgres/postgres_impl
import ../../log
import ../../enums
import ../database_types
import ./query/postgres_builder
import ./postgres_types


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


proc where*(self: PostgresQuery, column: string, symbol: string, value: nil.type): PostgresQuery =
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
      "column": column
    }]
  else:
    self.query["where_null"].add(%*{
      "column": column
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


proc inTransaction*(self:PostgresQuery, connI:int) =
  ## Only used in transation block
  self.isInTransaction = true
  self.transactionConn = connI


proc freeTransactionConn*(self:PostgresQuery, connI:int) =
  ## Only used in transation block
  self.isInTransaction = false


# ================================================================================
# connection
# ================================================================================

proc getFreeConn(self:PostgresQuery | RawPostgresQuery):Future[int] {.async.} =
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


proc returnConn(self: PostgresQuery | RawPostgresQuery, i: int) {.async.} =
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

proc exec(self:PostgresQuery, queryString:string, args:JsonNode) {.async.} =
  ## args is `JObject`
  var connI = self.transactionConn
  if not self.isInTransaction:
    connI = getFreeConn(self).await
  defer:
    if not self.isInTransaction:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return

  var strArgs:seq[string]
  for (key, val) in args.pairs:
    case val.kind
    of JBool:
      strArgs.add($val.getBool)
    of JInt:
      strArgs.add($val.getInt)
    of JFloat:
      strArgs.add($val.getFloat)
    of JString:
      strArgs.add($val.getStr)
    of JNull:
      strArgs.add("NULL")
    else:
      strArgs.add(val.pretty)

  postgres_impl.exec(self.pools[connI].conn, queryString, strArgs, self.timeout).await


proc exec(self:RawPostgresQuery, queryString:string, args:JsonNode) {.async.} =
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
      strArgs.add($arg["value"].getBool)
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

  postgres_impl.exec(self.pools[connI].conn, queryString, strArgs, self.timeout).await


# ================================================================================
# public exec
# ================================================================================

proc insert*(self:PostgresQuery, items:JsonNode) {.async.} =
  ## items is `JObject`
  let sql = self.insertValueBuilder(items)
  self.log.logger(sql)
  self.exec(sql, items).await


proc exec*(self: RawPostgresQuery) {.async.} =
  ## It is only used with raw()
  self.log.logger(self.queryString)
  self.exec(self.queryString, self.placeHolder).await
