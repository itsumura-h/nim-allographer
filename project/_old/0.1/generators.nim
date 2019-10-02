import json
from strformat import `&`
from strutils import contains


## ==================================================
## SELECT
## ==================================================

proc selectSql*(queryArg: JsonNode): string =
  var query = queryArg
  var queryString = ""

  queryString.add("SELECT")

  if query.hasKey("select"):
    for i, item in query["select"].getElems():
      if i > 0:
        queryString.add(",")

      queryString.add(&" {item.getStr()}")
  else:
    queryString.add(" *")

  return queryString


proc selectCountSql*(queryArg: JsonNode): string =
  var query = queryArg
  var queryString = ""

  queryString.add("SELECT")

  if query.hasKey("select"):
    for i, item in query["select"].getElems():
      if i > 0:
        queryString.add(",")

      queryString.add(&" COUNT({item.getStr()})")
  else:
    queryString.add(&" COUNT(*)")

  return queryString


proc fromSql*(queryStringArg: string, queryArg: JsonNode): string =
  var query = queryArg
  var queryString = queryStringArg

  let table = query["table"].getStr()
  queryString.add(&" FROM {table}")

  return queryString


proc joinSql*(queryStringArg: string, queryArg: JsonNode): string =
  var query = queryArg
  var queryString = queryStringArg

  if query.hasKey("join"):
    for row in query["join"]:
      var table = row["table"].getStr()
      var column1 = row["column1"].getStr()
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()

      queryString.add(&" JOIN {table} ON {column1} {symbol} {column2}")

  return queryString


proc whereSql*(queryStringArg: string, queryArg: JsonNode): string =
  var query = queryArg
  var queryString = queryStringArg

  if query.hasKey("where"):
    for i, row in query["where"].getElems():
      var column = row["column"].getStr()
      var symbol = row["symbol"].getStr()
      var value = row["value"]
      
      if i == 0:
        queryString.add(&" WHERE {column} {symbol} {value}")
      else:
        queryString.add(&" AND {column} {symbol} {value}")

  return queryString


proc orWhereSql*(queryStringArg: string, queryArg: JsonNode): string =
  var query = queryArg
  var queryString = queryStringArg

  if query.hasKey("or_where"):
    for row in query["or_where"]:
      var column = row["column"].getStr()
      var symbol = row["symbol"].getStr()
      var value = row["value"]
      
      if queryString.contains("WHERE"):
        queryString.add(&" OR {column} {symbol} {value}")
      else:
        queryString.add(&" WHERE {column} {symbol} {value}")

  return queryString


proc limitSql*(queryStringArg: string, queryArg: JsonNode): string =
  var query = queryArg
  var queryString = queryStringArg

  if query.hasKey("limit"):
    var num = query["limit"].getInt()
    queryString.add(&" LIMIT {num}")

  return queryString


proc offsetSql*(queryStringArg: string, queryArg: JsonNode): string =
  var query = queryArg
  var queryString = queryStringArg

  if query.hasKey("offset"):
    var num = query["offset"].getInt()
    queryString.add(&" OFFSET {num}")

  return queryString


## ==================================================
## INSERT
## ==================================================
proc insertSql*(queryArg: JsonNode): string =
  let table = queryArg["table"].getStr()
  return &"INSERT INTO {table}"


proc insertValuesSqlByJsonNode*(queryStringArg: string, items: JsonNode): string =
  var queryString = queryStringArg
  var columns = ""
  var values = ""

  var i = 0
  for item in items.pairs:
    if i > 0:
      columns.add(", ")
      values.add(", ")
    i += 1
    columns.add(&"{item.key}")
    values.add(&"{item.val}")

  queryString.add(&" ({columns}) VALUES ({values})")
  return queryString


proc insertMultiValuesSql*(queryStringArg: string, rows: openArray[JsonNode]): string =
  var queryString = queryStringArg

  var columns = ""
  var rowsCount = 0
  for key, value in rows[0]:
    if rowsCount > 0:
      columns.add(", ")
    rowsCount += 1
    columns.add(&"{key}")

  var values = ""
  var valuesCount = 0
  for items in rows:
    var valueCount = 0
    var value = ""
    for item in items.pairs:
      if valueCount > 0:
        value.add(", ")
      valueCount += 1
      value.add(&"{item.val}")

    if valuesCount > 0:
      values.add(", ")
    valuesCount += 1
    values.add(&"({value})")

  queryString.add(&" ({columns}) VALUES {values}")
  return queryString


## ==================================================
## UPDATE
## ==================================================

proc updateSql*(queryArg: JsonNode): string =
  var query = queryArg
  var queryString = ""

  queryString.add("UPDATE")

  let table = query["table"].getStr()
  queryString.add(&" {table} SET ")

  return queryString


proc updateValuesSql*(queryStringArg: string, items:JsonNode): string =
  var queryString = queryStringArg
  var value = ""

  var i = 0
  for item in items.pairs:
    if i > 0:
      value.add(", ")
    i += 1
    value.add(&"{item.key} = {item.val}")

  queryString.add(value)
  return queryString


## ==================================================
## DELETE
## ==================================================

proc deleteSql*(): string =
  var queryString = "DELETE"
  return queryString
