import json


proc table*(table: string): JsonNode =
  ## Specify the table to use
  ##
  ## ========================== ==========================
  ## Nim                        SQL
  ## ========================== ==========================
  ## table("users").select()    SELECT * FROM users
  ## ========================== ==========================
  ##
  ## .. code-block:: sql
  ##   SELECT * FROM {table}
  ##   INSERT INTO {table}
  ##   UPDATE {table}
  ##   DELETE FROM {table}
  return %*{"table": table}


## ============================== SELECT ==============================

proc select*(queryArg: JsonNode, columnsArg: varargs[string]): JsonNode =
  ## Specify the columns to get data. If `columnsArg` is empty, get all columns.
  ## 
  ## ===================================== =====================================
  ## Nim                                   SQL
  ## ===================================== =====================================
  ## table("users").select()               SELECT * FROM users
  ## table("users").select("id", "name")   SELECT id, name FROM users
  ## ===================================== =====================================
  var query = queryArg

  if columnsArg.len == 0:
    query["select"] = %["*"]
  else:
    query["select"] = %*columnsArg
  
  return query


## ============================== Conditions ==============================

proc where*(queryArg: JsonNode, column: string, symbol: string, value: string): JsonNode =
  var query = queryArg

  if query.hasKey("where") == false:
    query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )

  return query


proc where*(queryArg: JsonNode, column: string, symbol: string, value: int): JsonNode =
  var query = queryArg

  if query.hasKey("where") == false:
    query["where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    query["where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )

  return query


proc orWhere*(queryArg: JsonNode, column: string, symbol: string, value: string): JsonNode =
  var query = queryArg

  if query.hasKey("or_where") == false:
    query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    query["or_where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )

  return query


proc orWhere*(queryArg: JsonNode, column: string, symbol: string, value: int): JsonNode =
  var query = queryArg

  if query.hasKey("or_where") == false:
    query["or_where"] = %*[{
      "column": column,
      "symbol": symbol,
      "value": value
    }]
  else:
    query["or_where"].add(
      %*{
        "column": column,
        "symbol": symbol,
        "value": value
      }
    )

  return query


proc join*(queryArg: JsonNode,
            table: string, 
            column1: string, 
            symbol: string, 
            column2: string): JsonNode =
  var query = queryArg

  if query.hasKey("join") == false:
    query["join"] = %*[{
      "table": table,
      "column1": column1,
      "symbol": symbol,
      "column2": column2
    }]
  else:
    query["join"].add(
      %*{
        "table": table,
        "column1": column1,
        "symbol": symbol,
        "column2": column2
      }
    )

  return query


proc offset*(queryArg: JsonNode, num: int): JsonNode =
  var query = queryArg
  query["offset"] = %num
  return query


proc limit*(queryArg: JsonNode, num: int): JsonNode =
  var query = queryArg
  query["limit"] = %num
  return query

