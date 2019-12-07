import json
from strformat import `&`
from strutils import contains

import ../base

# ==================== SELECT ====================

proc selectSql*(this: RDB): RDB =
  var queryString = ""

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


proc selectByIdSql*(this: RDB, id: int, key: string): RDB =
  this.sqlString.add(&" WHERE {key} = {$id} LIMIT 1")
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
      case row["value"].kind:
      of JInt:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getInt()
        if i == 0:
          this.sqlString.add(&" WHERE {column} {symbol} {value}")
        else:
          this.sqlString.add(&" AND {column} {symbol} {value}")
      of JFloat:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getInt()
        if i == 0:
          this.sqlString.add(&" WHERE {column} {symbol} {value}")
        else:
          this.sqlString.add(&" AND {column} {symbol} {value}")
      of JBool:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getBool()
        if i == 0:
          this.sqlString.add(&" WHERE {column} {symbol} {value}")
        else:
          this.sqlString.add(&" AND {column} {symbol} {value}")
      else:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getStr()
        if i == 0:
          this.sqlString.add(&" WHERE {column} {symbol} '{value}'")
        else:
          this.sqlString.add(&" AND {column} {symbol} '{value}'")

  return this


proc orWhereSql*(this: RDB): RDB =
  if this.query.hasKey("or_where"):
    for i, row in this.query["or_where"].getElems():
      case row["value"].kind:
      of JInt:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getInt()
        if this.sqlString.contains("WHERE"):
          this.sqlString.add(&" OR {column} {symbol} {value}")
        else:
          this.sqlString.add(&" WHERE {column} {symbol} {value}")
      of JFloat:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getInt()
        if this.sqlString.contains("WHERE"):
          this.sqlString.add(&" OR {column} {symbol} {value}")
        else:
          this.sqlString.add(&" WHERE {column} {symbol} {value}")
      of JBool:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getBool()
        if this.sqlString.contains("WHERE"):
          this.sqlString.add(&" OR {column} {symbol} {value}")
        else:
          this.sqlString.add(&" WHERE {column} {symbol} {value}")
      else:
        var column = row["column"].getStr()
        var symbol = row["symbol"].getStr()
        var value = row["value"].getStr()
        if this.sqlString.contains("WHERE"):
          this.sqlString.add(&" OR {column} {symbol} '{value}'")
        else:
          this.sqlString.add(&" WHERE {column} {symbol} '{value}'")

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
    columns.add(item.key)
    case item.val.kind:
    of JInt:
      values.add(&"{item.val.getInt}")
    of JFloat:
      values.add(&"{item.val.getFloat}")
    of JBool:
      values.add(&"{item.val.getBool}")
    else:
      values.add(&"'{item.val.getStr}'")

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
      case val.kind:
      of JInt:
        value.add(&"{val.getInt}")
      of JFloat:
        value.add(&"{val.getFloat}")
      of JBool:
        value.add(&"{val.getBool}")
      else:
        value.add(&"'{val.getStr}'")

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
  for item in items.pairs:
    if i > 0: value.add(", ")
    i += 1
    case item.val.kind:
    of JInt:
      value.add(&"{item.key} = {item.val.getInt}")
    of JFloat:
      value.add(&"{item.key} = {item.val.getFloat}")
    of JBool:
      value.add(&"{item.key} = {item.val.getBool}")
    else:
      value.add(&"{item.key} = '{item.val.getStr}'")

  this.sqlString.add(value)
  return this


# ==================== DELETE ====================

proc deleteSql*(this: RDB): RDB =
  this.sqlString.add("DELETE")
  return this

proc deleteByIdSql*(this: RDB, id: int, key: string): RDB =
  this.sqlString.add(&" WHERE {key} = {id}")
  return this
