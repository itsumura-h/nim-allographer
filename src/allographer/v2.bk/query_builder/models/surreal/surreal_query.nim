import std/asyncdispatch
import std/json
import std/options
import std/strutils
import std/times
import ../../libs/surreal/surreal_impl
import ../../enums
import ./surreal_types


proc select*(self:SurrealConnections, columnsArg:varargs[string]):SurrealQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let surrealQuery = SurrealQuery.new(
    self.log,
    self.pools,
    query
  )
  return surrealQuery


proc table*(self:SurrealConnections, tableArg: string): SurrealQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let surrealQuery = SurrealQuery.new(
    self.log,
    self.pools,
    query,
  )
  return surrealQuery


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
      CatchableError,
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
      CatchableError,
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
      CatchableError,
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
      CatchableError,
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
      CatchableError,
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
      CatchableError,
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


proc raw*(self:SurrealConnections, sql:string, arges=newJArray()): RawSurrealQuery =
  ## arges is `JArray`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawSurrealQuery(
    log: self.log,
    pools: self.pools,
    query: newJObject(),
    queryString: sql.strip(),
    placeHolder: arges,
  )
  return rawQueryRdb
