import json
from strformat import `&`
from strutils import contains, isUpperAscii

import base, ../connection
from ../utils import wrapUpper


# ==================== SELECT ====================

proc selectSql*(self: RDB): RDB =
  var queryString = ""

  if self.query.hasKey("distinct"):
    queryString.add("SELECT DISTINCT")
  else:
    queryString.add("SELECT")

  if self.query.hasKey("select"):
    for i, item in self.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      wrapUpper(column)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  self.sqlString = queryString
  return self


proc fromSql*(self: RDB): RDB =
  var table = self.query["table"].getStr()
  wrapUpper(table)
  self.sqlString.add(&" FROM {table}")
  return self

proc selectFirstSql*(self:RDB): RDB =
  self.sqlString.add(" LIMIT 1")
  return self

proc selectByIdSql*(self:RDB, id:int, key:string): RDB =
  var key = key
  wrapUpper(key)
  if self.sqlString.contains("WHERE"):
    self.sqlString.add(&" AND {key} = ? LIMIT 1")
  else:
    self.sqlString.add(&" WHERE {key} = ? LIMIT 1")
  return self


proc joinSql*(self: RDB): RDB =
  if self.query.hasKey("join"):
    for row in self.query["join"]:
      var table = row["table"].getStr()
      wrapUpper(table)
      var column1 = row["column1"].getStr()
      wrapUpper(column1)
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()
      wrapUpper(column2)

      self.sqlString.add(&" INNER JOIN {table} ON {column1} {symbol} {column2}")

  return self


proc leftJoinSql*(self: RDB): RDB =
  if self.query.hasKey("left_join"):
    for row in self.query["left_join"]:
      var table = row["table"].getStr()
      wrapUpper(table)
      var column1 = row["column1"].getStr()
      wrapUpper(column1)
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()
      wrapUpper(column2)

      self.sqlString.add(&" LEFT JOIN {table} ON {column1} {symbol} {column2}")

  return self


proc whereSql*(self: RDB): RDB =
  if self.query.hasKey("where"):
    for i, row in self.query["where"].getElems():
      var column = row["column"].getStr()
      wrapUpper(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        self.sqlString.add(&" WHERE {column} {symbol} {value}")
      else:
        self.sqlString.add(&" AND {column} {symbol} {value}")

  return self


proc orWhereSql*(self: RDB): RDB =
  if self.query.hasKey("or_where"):
    for row in self.query["or_where"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if self.sqlString.contains("WHERE"):
        self.sqlString.add(&" OR {column} {symbol} {value}")
      else:
        self.sqlString.add(&" WHERE {column} {symbol} {value}")

  return self


proc whereBetweenSql*(self:RDB): RDB =
  if self.query.hasKey("where_between"):
    for row in self.query["where_between"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if self.sqlString.contains("WHERE"):
        self.sqlString.add(&" AND {column} BETWEEN {start} AND {stop}")
      else:
        self.sqlString.add(&" WHERE {column} BETWEEN {start} AND {stop}")

  return self


proc whereNotBetweenSql*(self:RDB): RDB =
  if self.query.hasKey("where_not_between"):
    for row in self.query["where_not_between"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if self.sqlString.contains("WHERE"):
        self.sqlString.add(&" AND {column} NOT BETWEEN {start} AND {stop}")
      else:
        self.sqlString.add(&" WHERE {column} NOT BETWEEN {start} AND {stop}")
  return self


proc whereInSql*(self:RDB): RDB =
  if self.query.hasKey("where_in"):
    var widthString = ""
    for row in self.query["where_in"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))

      if self.sqlString.contains("WHERE"):
        self.sqlString.add(&" AND {column} IN ({widthString})")
      else:
        self.sqlString.add(&" WHERE {column} IN ({widthString})")
  return self


proc whereNotInSql*(self:RDB): RDB =
  if self.query.hasKey("where_not_in"):
    var widthString = ""
    for row in self.query["where_not_in"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))

      if self.sqlString.contains("WHERE"):
        self.sqlString.add(&" AND {column} NOT IN ({widthString})")
      else:
        self.sqlString.add(&" WHERE {column} NOT IN ({widthString})")
  return self


proc whereNullSql*(self:RDB): RDB =
  if self.query.hasKey("where_null"):
    for row in self.query["where_null"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      if self.sqlString.contains("WHERE"):
        self.sqlString.add(&" AND {column} is null")
      else:
        self.sqlString.add(&" WHERE {column} is null")
  return self


proc groupBySql*(self:RDB): RDB =
  if self.query.hasKey("group_by"):
    for row in self.query["group_by"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      if self.sqlString.contains("GROUP BY"):
        self.sqlString.add(&", {column}")
      else:
        self.sqlString.add(&" GROUP BY {column}")
  return self


proc havingSql*(self:RDB): RDB =
  if self.query.hasKey("having"):
    for i, row in self.query["having"].getElems():
      var column = row["column"].getStr()
      wrapUpper(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        self.sqlString.add(&" HAVING {column} {symbol} {value}")
      else:
        self.sqlString.add(&" AND {column} {symbol} {value}")

  return self


proc orderBySql*(self:RDB): RDB =
  if self.query.hasKey("order_by"):
    for row in self.query["order_by"]:
      var column = row["column"].getStr()
      wrapUpper(column)
      var order = row["order"].getStr()

      if self.sqlString.contains("ORDER BY"):
        self.sqlString.add(&", {column} {order}")
      else:
        self.sqlString.add(&" ORDER BY {column} {order}")
  return self


proc limitSql*(self: RDB): RDB =
  if self.query.hasKey("limit"):
    var num = self.query["limit"].getInt()
    self.sqlString.add(&" LIMIT {num}")

  return self


proc offsetSql*(self: RDB): RDB =
  if self.query.hasKey("offset"):
    var num = self.query["offset"].getInt()
    self.sqlString.add(&" OFFSET {num}")

  return self


# ==================== INSERT ====================

proc insertSql*(self: RDB): RDB =
  var table = self.query["table"].getStr()
  wrapUpper(table)
  self.sqlString = &"INSERT INTO {table}"
  return self


proc insertValueSql*(self: RDB, items: JsonNode): RDB =
  var columns = ""
  var values = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0:
      columns.add(", ")
      values.add(", ")
    i += 1
    # If column name contains Upper letter, column name is covered by double quote
    var key = key
    wrapUpper(key)
    columns.add(key)

    if val.kind == JInt:
      self.placeHolder.add($(val.getInt()))
    elif val.kind == JFloat:
      self.placeHolder.add($(val.getFloat()))
    elif val.kind == JBool:
      let val =
        if val.getBool():
          1
        else:
          0
      self.placeHolder.add($val)
    elif val.kind == JObject:
      self.placeHolder.add($val)
    else:
      self.placeHolder.add(val.getStr())
    # values.add("?")
    let dbType = getDriver()
    if dbType == "postgres":
      values.add("$" & $i)
    else:
      values.add("?")

  self.sqlString.add(&" ({columns}) VALUES ({values})")
  return self


proc insertValuesSql*(self: RDB, rows: openArray[JsonNode]): RDB =
  var columns = ""
  var i = 0
  for key, value in rows[0]:
    if i > 0: columns.add(", ")
    i += 1
    # If column name contains Upper letter, column name is covered by double quote
    var key = key
    wrapUpper(key)
    columns.add(key)

  var values = ""
  var valuesCount = 0
  for items in rows:
    var valueCount = 0
    var value = ""
    for key, val in items.pairs:
      if valueCount > 0: value.add(", ")
      valueCount += 1
      if val.kind == JInt:
        self.placeHolder.add($(val.getInt()))
      elif val.kind == JFloat:
        self.placeHolder.add($(val.getFloat()))
      elif val.kind == JBool:
        let val =
          if val.getBool():
            1
          else:
            0
        self.placeHolder.add($val)
      elif val.kind == JObject:
        self.placeHolder.add($val)
      else:
        self.placeHolder.add(val.getStr())
      values.add("?")

    if valuesCount > 0: values.add(", ")
    valuesCount += 1
    values.add(&"({value})")

  self.sqlString.add(&" ({columns}) VALUES {values}")
  return self


# ==================== UPDATE ====================

proc updateSql*(self: RDB): RDB =
  self.sqlString.add("UPDATE")

  var table = self.query["table"].getStr()
  wrapUpper(table)
  self.sqlString.add(&" {table} SET ")
  return self


proc updateValuesSql*(self: RDB, items:JsonNode): RDB =
  var value = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0: value.add(", ")
    i += 1
    var key = key
    wrapUpper(key)
    value.add(&"{key} = ?")

  self.sqlString.add(value)
  return self


# ==================== DELETE ====================

proc deleteSql*(self: RDB): RDB =
  self.sqlString.add("DELETE")
  return self


proc deleteByIdSql*(self: RDB, id: int, key: string): RDB =
  var key = key
  wrapUpper(key)
  self.sqlString.add(&" WHERE {key} = ?")
  return self

# ==================== Aggregates ====================

proc selectCountSql*(self: RDB): RDB =
  self.sqlString = "SELECT count(*) as aggregate"
  return self


proc selectMaxSql*(self:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  self.sqlString = &"SELECT max({column}) as aggregate"
  return self


proc selectMinSql*(self:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  self.sqlString = &"SELECT min({column}) as aggregate"
  return self


proc selectAvgSql*(self:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  self.sqlString = &"SELECT avg({column}) as aggregate"
  return self


proc selectSumSql*(self:RDB, column:string): RDB =
  var column = column
  wrapUpper(column)
  self.sqlString = &"SELECT sum({column}) as aggregate"
  return self
