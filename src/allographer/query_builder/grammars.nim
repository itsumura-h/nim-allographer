import base
import json


proc table*(this: RDB, tableArg: string): RDB =
  this.query = %*{"table": tableArg}
  return this


# ============================== Raw query ==============================

proc raw*(this:RDB, sql:string, arges:varargs[string]): RDB =
  this.sqlString = sql
  this.sqlStringseq = @[sql]
  this.placeHolder = @arges
  return this


# ============================== SELECT ==============================

proc select*(this: RDB, columnsArg: varargs[string]): RDB =
  if columnsArg.len == 0:
    this.query["select"] = %["*"]
  else:
    this.query["select"] = %*columnsArg
  return this


proc `distinct`*(this: RDB): RDB =
  this.query["distinct"] = %true
  return this

# ============================== Conditions ==============================

proc where*(this: RDB, column: string, symbol: string, value: string): RDB =
  if not ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(
      Exception,
      """Arg position 3 is only allowed of ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"]"""
    )

  this.placeHolder.add(value)

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
  if not ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(
      Exception,
      """Arg position 3 is only allowed of ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"]"""
    )

  this.placeHolder.add($value)

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

proc where*(this: RDB, column: string, symbol: string, value: nil.type): RDB =
  if not ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(
      Exception,
      """Arg position 3 is only allowed of ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"]"""
    )

  if this.query.hasKey("where") == false:
    this.query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "null"
    }]
  else:
    this.query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": "null"
      }
    )
  return this


proc orWhere*(this: RDB, column: string, symbol: string, value: string): RDB =
  if not ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(
      Exception,
      """Arg position 3 is only allowed of ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"]"""
    )

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
  if not ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(
      Exception,
      """Arg position 3 is only allowed of ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"]"""
    )

  this.placeHolder.add($value)

  if this.query.hasKey("or_where") == false:
    this.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    this.query["or_where"].add(%*{
      "column": column,
      "symbol": symbol,
      "value": "?"
    })
  return this

proc orWhere*(this: RDB, column: string, symbol: string, value: float): RDB =
  if not ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"].contains(symbol):
    raise newException(
      Exception,
      """Arg position 3 is only allowed of ["is", "is not", "=", "<", "=<", "=>", ">", "LIKE","%LIKE","LIKE%","%LIKE%"]"""
    )

  this.placeHolder.add($value)

  if this.query.hasKey("or_where") == false:
    this.query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": "?"
    }]
  else:
    this.query["or_where"].add(%*{
      "column": column,
      "symbol": symbol,
      "value": "?"
    })
  return this


proc whereBetween*(this:RDB, column:string, width:array[2, int]): RDB =
  if this.query.hasKey("where_between") == false:
    this.query["where_between"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    this.query["where_between"].add(%*{
      "column": column,
      "width": width
    })
  return this

proc whereBetween*(this:RDB, column:string, width:array[2, float]): RDB =
  if this.query.hasKey("where_between") == false:
    this.query["where_between"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    this.query["where_between"].add(%*{
      "column": column,
      "width": width
    })
  return this


proc whereNotBetween*(this:RDB, column:string, width:array[2, int]): RDB =
  if this.query.hasKey("where_not_between") == false:
    this.query["where_not_between"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    this.query["where_not_between"].add(%*{
      "column": column,
      "width": width
    })
  return this

proc whereNotBetween*(this:RDB, column:string, width:array[2, float]): RDB =
  if this.query.hasKey("where_not_between") == false:
    this.query["where_not_between"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    this.query["where_not_between"].add(%*{
      "column": column,
      "width": width
    })
  return this


proc whereIn*(this:RDB, column:string, width:seq[int]): RDB =
  if this.query.hasKey("where_in") == false:
    this.query["where_in"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    this.query["where_in"].add(%*{
      "column": column,
      "width": width
    })
  return this

proc whereIn*(this:RDB, column:string, width:seq[float]): RDB =
  if this.query.hasKey("where_in") == false:
    this.query["where_in"] = %*[{
      "column": column,
      "width": width
    }]
  else:
    this.query["where_in"].add(%*{
      "column": column,
      "width": width
    })
  return this


proc join*(this: RDB, table: string, column1: string, symbol: string,
            column2: string): RDB =
  if this.query.hasKey("join") == false:
    this.query["join"] = %*[{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    }]
  else:
    this.query["join"].add(%*{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    })
  return this


proc limit*(this: RDB, num: int): RDB =
  this.query["limit"] = %num
  return this


proc offset*(this: RDB, num: int): RDB =
  this.query["offset"] = %num
  return this
