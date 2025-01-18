import std/asyncdispatch
import std/json
import std/options
import std/strutils
import std/times
import ../../libs/mysql/mysql_impl
import ../../enums
import ./mysql_types


proc select*(self:MysqlConnections, columnsArg:varargs[string]):MysqlQuery =
  let query = newJObject()
  
  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %columnsArg
  
  let mysqlQuery = MysqlQuery(
    log: self.log,
    pools: self.pools,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return mysqlQuery


proc table*(self:MysqlConnections, tableArg: string): MysqlQuery =
  let query = newJObject()
  query["table"] = %tableArg

  let mysqlQuery = MysqlQuery(
    log: self.log,
    pools: self.pools,
    query: query,
    queryString: "",
    placeHolder: newJArray(),
    isInTransaction: self.isInTransaction,
    transactionConn: self.transactionConn,
  )
  return mysqlQuery


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


proc where*(self: MysqlQuery, column: string, symbol: string,
            value: bool): MysqlQuery =
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


proc where*(self: MysqlQuery, column: string, symbol: string, value: nil.type): MysqlQuery =
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


proc orWhere*(self: MysqlQuery, column: string, symbol: string,
              value: string|int|float|bool): MysqlQuery =
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


proc orWhere*(self: MysqlQuery, column: string, symbol: string, value: nil.type): MysqlQuery =
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

proc having*(self: MysqlQuery, column: string, symbol: string, value: nil.type): MysqlQuery =
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


proc raw*(self:MysqlConnections, sql:string, arges=newJArray()): RawMysqlQuery =
  ## arges is `JArray` `[true, 1, 1.1, "str"]`
  ## 
  ## can't use BLOB data.
  let rawQueryRdb = RawMysqlQuery(
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
