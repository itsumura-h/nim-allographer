import std/asyncdispatch
import std/json
import std/options
import std/strutils
import std/times
import ../../libs/mariadb/mariadb_impl
import ../../enums
import ./mariadb_types


proc select*(self:MariadbConnections, columnsArg:varargs[string]):MariadbQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let MariadbQuery = MariadbQuery(
    log: self.log,
    pools: self.pools,
    info: self.info,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return MariadbQuery


proc table*(self:MariadbConnections, tableArg: string): MariadbQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let MariadbQuery = MariadbQuery(
    log: self.log,
    pools: self.pools,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return MariadbQuery


proc table*(self:MariadbQuery, tableArg: string): MariadbQuery =
  self.query["table"] = %tableArg
  return self


proc `distinct`*(self: MariadbQuery): MariadbQuery =
  self.query["distinct"] = %true
  return self

# ============================== Conditions ==============================

proc join*(self: MariadbQuery, table: string, column1: string, symbol: string,
            column2: string): MariadbQuery =
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


proc leftJoin*(self: MariadbQuery, table: string, column1: string, symbol: string,
              column2: string): MariadbQuery =
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

proc where*(self: MariadbQuery, column: string, symbol: string,
            value: string|int|float): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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


proc where*(self: MariadbQuery, column: string, symbol: string,
            value: bool): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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


proc where*(self: MariadbQuery, column: string, symbol: string, value: nil.type): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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


proc orWhere*(self: MariadbQuery, column: string, symbol: string,
              value: string|int|float|bool): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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


proc orWhere*(self: MariadbQuery, column: string, symbol: string, value: nil.type): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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


proc whereBetween*(self:MariadbQuery, column:string, width:array[2, int|float]): MariadbQuery =
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


proc whereBetween*(self:MariadbQuery, column:string, width:array[2, string]): MariadbQuery =
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


proc whereNotBetween*(self:MariadbQuery, column:string, width:array[2, int|float]): MariadbQuery =
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


proc whereNotBetween*(self:MariadbQuery, column:string, width:array[2, string]): MariadbQuery =
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


proc whereIn*(self:MariadbQuery, column:string, width:seq[int|float|string]): MariadbQuery =
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


proc whereNotIn*(self:MariadbQuery, column:string, width:seq[int|float|string]): MariadbQuery =
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


proc whereNull*(self:MariadbQuery, column:string): MariadbQuery =
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


proc groupBy*(self:MariadbQuery, column:string): MariadbQuery =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc having*(self: MariadbQuery, column: string, symbol: string,
              value: string|int|float|bool): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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

proc having*(self: MariadbQuery, column: string, symbol: string, value: nil.type): MariadbQuery =
  if not whereSymbols.contains(symbol):
    raise newException(
      CatchableError,
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


proc orderBy*(self:MariadbQuery, column:string, order:Order): MariadbQuery =
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


proc limit*(self: MariadbQuery, num: int): MariadbQuery =
  self.query["limit"] = %num
  return self


proc offset*(self: MariadbQuery, num: int): MariadbQuery =
  self.query["offset"] = %num
  return self


proc raw*(self:MariadbConnections, sql:string, arges=newJArray()): RawMariadbQuery =
  ## arges is `JArray` `[true, 1, 1.1, "str"]`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawMariadbQuery(
    log: self.log,
    pools: self.pools,
    info: self.info,
    query: newJObject(),
    queryString: sql.strip(),
    placeHolder: arges,
    isInTransaction: false,
    transactionConn: 0
  )
  return rawQueryRdb
