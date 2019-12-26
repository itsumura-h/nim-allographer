import json
from strformat import `&`
from strutils import contains

import ../base

# ==================== SELECT ====================

proc selectSql*(this: RDB): RDB =
  var queryString = ""

  if this.query.hasKey("distinct"):
    queryString.add("SELECT DISTINCT")
  else:
    queryString.add("SELECT")

  if this.query.hasKey("select"):
    for i, item in this.query["select"].getElems():
      if i > 0: queryString.add(",")
      queryString.add(&" {item.getStr()}")
  else:
    queryString.add(" *")

  this.sqlString = queryString
  return this


proc fromSql*(this: RDB): RDB =
  let table = this.query["table"].getStr()
  this.sqlString.add(&" FROM {table}")
  return this


proc selectByIdSql*(this: RDB, key: string): RDB =
  this.sqlString.add(&" WHERE {key} = ? LIMIT 1")
  return this


proc joinSql*(this: RDB): RDB =
  if this.query.hasKey("join"):
    for row in this.query["join"]:
      var table = row["table"].getStr()
      var column1 = row["column1"].getStr()
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()

      this.sqlString.add(&" JOIN {table} ON {column1} {symbol} {column2}")

  return this


proc whereSql*(this: RDB): RDB =
  if this.query.hasKey("where"):
    for i, row in this.query["where"].getElems():
      var column = row["column"].getStr()
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()
      
      if i == 0:
        this.sqlString.add(&" WHERE {column} {symbol} {value}")
      else:
        this.sqlString.add(&" AND {column} {symbol} {value}")

  return this


proc orWhereSql*(this: RDB): RDB =
  if this.query.hasKey("or_where"):
    for row in this.query["or_where"]:
      var column = row["column"].getStr()
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()
      
      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" OR {column} {symbol} {value}")
      else:
        this.sqlString.add(&" WHERE {column} {symbol} {value}")

  return this


proc whereBetweenSql*(this:RDB): RDB =
  if this.query.hasKey("where_between"):
    for row in this.query["where_between"]:
      var column = row["column"].getStr()
      var start = row["width"][0].getInt()
      var stop = row["width"][1].getInt()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} BETWEEN {start} AND {stop}")
      else:
        this.sqlString.add(&" WHERE {column} BETWEEN {start} AND {stop}")

  return this


proc whereNotBetweenSql*(this:RDB): RDB =
  if this.query.hasKey("where_not_between"):
    for row in this.query["where_not_between"]:
      var column = row["column"].getStr()
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} NOT BETWEEN {start} AND {stop}")
      else:
        this.sqlString.add(&" WHERE {column} NOT BETWEEN {start} AND {stop}")
  return this


proc whereInSql*(this:RDB): RDB =
  if this.query.hasKey("where_in"):
    var widthString = ""
    for row in this.query["where_in"]:
      var column = row["column"].getStr()
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} IN ({widthString})")
      else:
        this.sqlString.add(&" WHERE {column} IN ({widthString})")
  return this


proc limitSql*(this: RDB): RDB =
  if this.query.hasKey("limit"):
    var num = this.query["limit"].getInt()
    this.sqlString.add(&" LIMIT {num}")

  return this


proc offsetSql*(this: RDB): RDB =
  if this.query.hasKey("offset"):
    var num = this.query["offset"].getInt()
    this.sqlString.add(&" OFFSET {num}")

  return this


# ==================== INSERT ====================

proc insertSql*(this: RDB): RDB =
  let table = this.query["table"].getStr()
  this.sqlString = &"INSERT INTO {table}"
  return this


proc insertValueSql*(this: RDB, items: JsonNode): RDB =
  var columns = ""
  var values = ""

  var i = 0
  for item in items.pairs:
    if i > 0:
      columns.add(", ")
      values.add(", ")
    i += 1
    columns.add(&"{item.key}")
    if item.val.kind == JInt:
      this.placeHolder.add($(item.val.getInt()))
    elif item.val.kind == JFloat:
      this.placeHolder.add($(item.val.getFloat()))
    else:
      this.placeHolder.add(item.val.getStr())
    values.add("?")

  this.sqlString.add(&" ({columns}) VALUES ({values})")
  return this


proc insertValuesSql*(this: RDB, rows: openArray[JsonNode]): RDB =
  var columns = ""
  var rowsCount = 0

  for key, value in rows[0]:
    if rowsCount > 0: columns.add(", ")
    rowsCount += 1
    columns.add(&"{key}")

  var values = ""
  var valuesCount = 0
  for items in rows:
    var valueCount = 0
    var value = ""
    for key, val in items.pairs:
      if valueCount > 0: value.add(", ")
      valueCount += 1
      if val.kind == JInt:
        this.placeHolder.add($(val.getInt()))
      elif val.kind == JFloat:
        this.placeHolder.add($(val.getFloat()))
      else:
        this.placeHolder.add(val.getStr())
      value.add("?")

    if valuesCount > 0: values.add(", ")
    valuesCount += 1
    values.add(&"({value})")

  this.sqlString.add(&" ({columns}) VALUES {values}")
  return this


# ==================== UPDATE ====================

proc updateSql*(this: RDB): RDB =
  this.sqlString.add("UPDATE")

  let table = this.query["table"].getStr()
  this.sqlString.add(&" {table} SET ")
  return this


proc updateValuesSql*(this: RDB, items:JsonNode): RDB =
  var value = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0: value.add(", ")
    i += 1
    value.add(&"{key} = ?")

  this.sqlString.add(value)
  return this


# ==================== DELETE ====================

proc deleteSql*(this: RDB): RDB =
  this.sqlString.add("DELETE")
  return this

proc deleteByIdSql*(this: RDB, id: int, key: string): RDB =
  this.sqlString.add(&" WHERE {key} = ?")
  return this
