import std/json
import ../../enums
import ../surreal_types


# https://surrealdb.com/docs/surrealql/statements/select
#[
SELECT
FROM
WHERE
SPLIT AT
ORDER BY
GROUP BY
LIMIT BY
START AT
FETCH
TIMEOUT
PARALLEL
]#

proc table*(self:SurrealDb, tableArg: string): SurrealDb =
  self.query = newJObject()
  self.query["table"] = %tableArg
  self.queryString = ""
  self.placeHolder = @[]
  return self


# ============================== Raw query ==============================

proc raw*(self:SurrealDb, sql:string, arges:varargs[string]): RawQuerySurrealDb =
  return  RawQuerySurrealDb(
    conn:self.conn,
    log: self.log,
    query: newJObject(),
    queryString: sql,
    placeHolder: @arges,
    isInTransaction:self.isInTransaction,
    transactionConn:self.transactionConn
  )


# ============================== SELECT ==============================

proc select*(self: SurrealDb, columnsArg: varargs[string]): SurrealDb =
  if columnsArg.len == 0:
    self.query["select"] = %["*"]
  else:
    self.query["select"] = %columnsArg
  return self


# ============================== Conditions ==============================

const whereSymbols = ["is", "is not", "=", "!=", "<", "<=", ">=", ">", "<>", "LIKE","%LIKE","LIKE%","%LIKE%"]
const whereSymbolsError = """Arg position 3 is only allowed of ["is", "is not", "=", "!=", "<", "<=", ">=", ">", "<>", "LIKE","%LIKE","LIKE%","%LIKE%"]"""

proc where*(self: SurrealDb, column: string, symbol: string,
            value: string|int|float|bool|SurrealId): SurrealDb =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  when value.type is SurrealId:
    self.placeHolder.add(value.rawId())
  else:
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


proc where*(self: SurrealDb, column: string, symbol: string, value: nil.type): SurrealDb =
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


proc orWhere*(self: SurrealDb, column: string, symbol: string,
              value: string|int|float|bool|SurrealId): SurrealDb =
  if not whereSymbols.contains(symbol):
    raise newException(
      Exception,
      whereSymbolsError
    )

  when value.type is SurrealId:
    self.placeHolder.add(value.rawId())
  else:
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

proc orWhere*(self: SurrealDb, column: string, symbol: string, value: nil.type): SurrealDb =
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


proc fetch*(self:SurrealDb, columnsArg: varargs[string]):SurrealDb =
  self.query["fetch"] = %columnsArg
  return self


proc groupBy*(self:SurrealDb, column:string): SurrealDb =
  if self.query.hasKey("group_by") == false:
    self.query["group_by"] = %*[{"column": column}]
  else:
    self.query["group_by"].add(%*{"column": column})
  return self


proc orderBy*(self:SurrealDb, column:string, order:Order): SurrealDb =
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

proc orderBy*(self:SurrealDb, column:string, collation:Collation, order:Order): SurrealDb =
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


proc limit*(self: SurrealDb, num: int): SurrealDb =
  self.query["limit"] = %num
  return self


proc start*(self: SurrealDb, num: int): SurrealDb =
  self.query["start"] = %num
  return self


proc parallel*(self: SurrealDb): SurrealDb =
  self.query["parallel"] = %true
  return self
