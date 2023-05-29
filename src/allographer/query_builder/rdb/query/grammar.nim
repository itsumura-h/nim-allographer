import std/json
import ../../enums
import ../rdb_types

#[
FROM
ON
JOIN
WHERE
GROUP BY
HAVINGconnection
SELECT
DISTINCT
ORDER BY
TOP（LIMIT）
]#

proc table*(self:Rdb, tableArg: string): Rdb =
  self.query = newJObject()
  self.query["table"] = %tableArg
  self.queryString = ""
  self.placeHolder = @[]
  return self


# ============================== Raw query ==============================

proc raw*(self:Rdb, sql:string, arges:varargs[string]): RawQueryRdb =
  let rawQueryRdb = RawQueryRdb(
    driver:self.driver,
    conn:self.conn,
    log: self.log,
    query: newJObject(),
    queryString: sql,
    placeHolder: @arges,
    isInTransaction:self.isInTransaction,
    transactionConn:self.transactionConn
  )
  return rawQueryRdb


# ============================== SELECT ==============================

proc select*(self: Rdb, columnsArg: varargs[string]): Rdb =
  if columnsArg.len == 0:
    self.query["select"] = %["*"]
  else:
    self.query["select"] = %columnsArg
  return self


proc `distinct`*(self: Rdb): Rdb =
  self.query["distinct"] = %true
  return self

# ============================== Conditions ==============================

proc join*(self: Rdb, table: string, column1: string, symbol: string,
            column2: string): Rdb =
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


proc leftJoin*(self: Rdb, table: string, column1: string, symbol: string,
              column2: string): Rdb =
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

proc where*(self: Rdb, column: string, symbol: string,
            value: string|int|float|bool): Rdb =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  self.placeHolder.add($value)

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


proc where*(self: Rdb, column: string, symbol: string, value: nil.type): Rdb =
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


proc orWhere*(self: Rdb, column: string, symbol: string,
              value: string|int|float|bool): Rdb =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  self.placeHolder.add($value)

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

proc orWhere*(self: Rdb, column: string, symbol: string, value: nil.type): Rdb =
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

proc whereBetween*(self:Rdb, column:string, width:array[2, int|float]): Rdb =
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

proc whereBetween*(self:Rdb, column:string, width:array[2, string]): Rdb =
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

proc whereNotBetween*(self:Rdb, column:string, width:array[2, int|float]): Rdb =
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

proc whereNotBetween*(self:Rdb, column:string, width:array[2, string]): Rdb =
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

proc whereIn*(self:Rdb, column:string, width:seq[int|float|string]): Rdb =
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


proc whereNotIn*(self:Rdb, column:string, width:seq[int|float|string]): Rdb =
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


proc whereNull*(self:Rdb, column:string): Rdb =
  if self.query.hasKey("where_null") == false:
    self.query["where_null"] = %*[{
      "column": column
    }]
  else:
    self.query["where_null"].add(%*{
      "column": column
    })
  return self


proc groupBy*(self:Rdb, column:string): Rdb =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc having*(self: Rdb, column: string, symbol: string,
              value: string|int|float|bool): Rdb =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )
    
  self.placeHolder.add($value)

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

proc having*(self: Rdb, column: string, symbol: string, value: nil.type): Rdb =
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


proc orderBy*(self:Rdb, column:string, order:Order): Rdb =
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


proc limit*(self: Rdb, num: int): Rdb =
  self.query["limit"] = %num
  return self


proc offset*(self: Rdb, num: int): Rdb =
  self.query["offset"] = %num
  return self

proc inTransaction*(self:Rdb, connI:int) =
  ## Only used in transation block
  self.isInTransaction = true
  self.transactionConn = connI

proc freeTransactionConn*(self:Rdb, connI:int) =
  ## Only used in transation block
  self.isInTransaction = false
