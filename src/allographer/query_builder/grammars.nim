import base
import json
from ../connection import dbQuote

proc table*(this: RDB, tableArg: string): RDB =
  this.query = %*{"table": tableArg}
  return this


# ============================== Raw query ==============================

proc raw*(this:RDB, sql:string): RDB =
  this.sqlString = sql
  this.sqlStringseq = @[sql]
  return this


# ============================== SELECT ==============================

proc select*(this: RDB, columnsArg: varargs[string]): RDB =
  if columnsArg.len == 0:
    this.query["select"] = %["*"]
  else:
    this.query["select"] = %*columnsArg
  
  return this


# ============================== Conditions ==============================

proc where*(this: RDB, column: string, symbol: string, value: string): RDB =
  this.placeHolder.add(value)

  if not ["=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(Exception, "symbol error")

  if this.query.hasKey("where") == false:
    this.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    this.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )

  return this

proc where*(this: RDB, column: string, symbol: string, value: int): RDB =
  this.placeHolder.add($value)

  if not ["=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(Exception, "symbol error")

  if this.query.hasKey("where") == false:
    this.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    this.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )
  return this

proc orWhere*(this: RDB, column: string, symbol: string, value: string): RDB =
  this.placeHolder.add(value)
  if this.query.hasKey("or_where") == false:
    this.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    this.query["or_where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )

  return this

proc orWhere*(this: RDB, column: string, symbol: string, value: int): RDB =
  this.placeHolder.add($value)
  if this.query.hasKey("or_where") == false:
    this.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    this.query["or_where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "?"
      }
    )

  return this


proc join*(this: RDB,
            table: string, 
            column1: string, 
            symbol: string, 
            column2: string): RDB =
  if this.query.hasKey("join") == false:
    this.query["join"] = %*[{
      "table": table.dbQuote(),
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    }]
  else:
    this.query["join"].add(
      %*{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
      }
    )

  return this


proc limit*(this: RDB, num: int): RDB =
  this.query["limit"] = %num
  return this


proc offset*(this: RDB, num: int): RDB =
  this.query["offset"] = %num
  return this

proc update*(this: RDB, items: JsonNode): RDB =
  for item in items.pairs:
    if item.val.kind == JInt:
      this.placeHolder.add($(item.val.getInt()))
    elif item.val.kind == JFloat:
      this.placeHolder.add($(item.val.getFloat()))
    else:
      this.placeHolder.add(item.val.getStr())

    this.query["update"] = items
  return this
