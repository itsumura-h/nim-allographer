# import json

# import ../util
# import base
# import
#   generators/sqlite_generator,
#   generators/mysql_generator,
#   generators/postgres_generator

import json
from strformat import `&`
from strutils import contains

import base

# ==================== SELECT ====================

proc selectSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectSql(this)
  # of "mysql":
  #   result = mysql_generator.selectSql(this)
  # of "postgres":
  #   result = postgres_generator.selectSql(this)
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
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.fromSql(this)
  # of "mysql":
  #   result = mysql_generator.fromSql(this)
  # of "postgres":
  #   result = postgres_generator.fromSql(this)
  let table = this.query["table"].getStr()
  this.sqlString.add(&" FROM {table}")
  return this


proc selectByIdSql*(this:RDB, id:int, key:string): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectByIdSql(this, key)
  # of "mysql":
  #   result = mysql_generator.selectByIdSql(this, key)
  # of "postgres":
  #   result = postgres_generator.selectByIdSql(this, key)
  this.sqlString.add(&" WHERE {key} = ? LIMIT 1")
  return this


proc joinSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.joinSql(this)
  # of "mysql":
  #   result = mysql_generator.joinSql(this)
  # of "postgres":
  #   result = postgres_generator.joinSql(this)
  if this.query.hasKey("join"):
    for row in this.query["join"]:
      var table = row["table"].getStr()
      var column1 = row["column1"].getStr()
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()

      this.sqlString.add(&" JOIN {table} ON {column1} {symbol} {column2}")

  return this


proc leftJoinSql*(this: RDB): RDB =
  if this.query.hasKey("left_join"):
    for row in this.query["left_join"]:
      var table = row["table"].getStr()
      var column1 = row["column1"].getStr()
      var symbol = row["symbol"].getStr()
      var column2 = row["column2"].getStr()

      this.sqlString.add(&" LEFT JOIN {table} ON {column1} {symbol} {column2}")

  return this


proc whereSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.whereSql(this)
  # of "mysql":
  #   result = mysql_generator.whereSql(this)
  # of "postgres":
  #   result = postgres_generator.whereSql(this)
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
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.orWhereSql(this)
  # of "mysql":
  #   result = mysql_generator.orWhereSql(this)
  # of "postgres":
  #   result = postgres_generator.orWhereSql(this)
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
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.whereBetweenSql(this)
  # of "mysql":
  #   result = mysql_generator.whereBetweenSql(this)
  # of "postgres":
  #   result = postgres_generator.whereBetweenSql(this)
  if this.query.hasKey("where_between"):
    for row in this.query["where_between"]:
      var column = row["column"].getStr()
      var start = row["width"][0].getFloat()
      var stop = row["width"][1].getFloat()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} BETWEEN {start} AND {stop}")
      else:
        this.sqlString.add(&" WHERE {column} BETWEEN {start} AND {stop}")

  return this


proc whereNotBetweenSql*(this:RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.whereNotBetweenSql(this)
  # of "mysql":
  #   result = mysql_generator.whereNotBetweenSql(this)
  # of "postgres":
  #   result = postgres_generator.whereNotBetweenSql(this)
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
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.whereInSql(this)
  # of "mysql":
  #   result = mysql_generator.whereInSql(this)
  # of "postgres":
  #   result = postgres_generator.whereInSql(this)
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


proc whereNotInSql*(this:RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.whereNotInSql(this)
  # of "mysql":
  #   result = mysql_generator.whereNotInSql(this)
  # of "postgres":
  #   result = postgres_generator.whereNotInSql(this)
  if this.query.hasKey("where_not_in"):
    var widthString = ""
    for row in this.query["where_not_in"]:
      var column = row["column"].getStr()
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        if val.kind == JInt:
          widthString.add($(val.getInt()))
        elif val.kind == JFloat:
          widthString.add($(val.getFloat()))

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} NOT IN ({widthString})")
      else:
        this.sqlString.add(&" WHERE {column} NOT IN ({widthString})")
  return this


proc whereNullSql*(this:RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.whereNullSql(this)
  # of "mysql":
  #   result = mysql_generator.whereNullSql(this)
  # of "postgres":
  #   result = postgres_generator.whereNullSql(this)
  if this.query.hasKey("where_null"):
    for row in this.query["where_null"]:
      var column = row["column"].getStr()

      if this.sqlString.contains("WHERE"):
        this.sqlString.add(&" AND {column} is null")
      else:
        this.sqlString.add(&" WHERE {column} is null")
  return this


proc groupBySql*(this:RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.groupBySql(this)
  # of "mysql":
  #   result = mysql_generator.groupBySql(this)
  # of "postgres":
  #   result = postgres_generator.groupBySql(this)
  if this.query.hasKey("group_by"):
    for row in this.query["group_by"]:
      var column = row["column"].getStr()

      if this.sqlString.contains("GROUP BY"):
        this.sqlString.add(&", {column}")
      else:
        this.sqlString.add(&" GROUP BY {column}")
  return this


proc havingSql*(this:RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.havingSql(this)
  # of "mysql":
  #   result = mysql_generator.havingSql(this)
  # of "postgres":
  #   result = postgres_generator.havingSql(this)
  if this.query.hasKey("having"):
    for i, row in this.query["having"].getElems():
      var column = row["column"].getStr()
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()
      
      if i == 0:
        this.sqlString.add(&" HAVING {column} {symbol} {value}")
      else:
        this.sqlString.add(&" AND {column} {symbol} {value}")

  return this


proc orderBySql*(this:RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.orderBySql(this)
  # of "mysql":
  #   result = mysql_generator.orderBySql(this)
  # of "postgres":
  #   result = postgres_generator.orderBySql(this)
  if this.query.hasKey("order_by"):
    for row in this.query["order_by"]:
      var column = row["column"].getStr()
      var order = row["order"].getStr()

      if this.sqlString.contains("ORDER BY"):
        this.sqlString.add(&", {column} {order}")
      else:
        this.sqlString.add(&" ORDER BY {column} {order}")
  return this


proc limitSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.limitSql(this)
  # of "mysql":
  #   result = mysql_generator.limitSql(this)
  # of "postgres":
  #   result = postgres_generator.limitSql(this)
  if this.query.hasKey("limit"):
    var num = this.query["limit"].getInt()
    this.sqlString.add(&" LIMIT {num}")

  return this


proc offsetSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.offsetSql(this)
  # of "mysql":
  #   result = mysql_generator.offsetSql(this)
  # of "postgres":
  #   result = postgres_generator.offsetSql(this)
  if this.query.hasKey("offset"):
    var num = this.query["offset"].getInt()
    this.sqlString.add(&" OFFSET {num}")

  return this


# ==================== INSERT ====================

proc insertSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.insertSql(this)
  # of "mysql":
  #   result = mysql_generator.insertSql(this)
  # of "postgres":
  #   result = postgres_generator.insertSql(this)
  let table = this.query["table"].getStr()
  this.sqlString = &"INSERT INTO {table}"
  return this


proc insertValueSql*(this: RDB, items: JsonNode): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.insertValueSql(this, items)
  # of "mysql":
  #   result = mysql_generator.insertValueSql(this, items)
  # of "postgres":
  #   result = postgres_generator.insertValueSql(this, items)
  var columns = ""
  var values = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0:
      columns.add(", ")
      values.add(", ")
    i += 1
    columns.add(key)
    if val.kind == JInt:
      this.placeHolder.add($(val.getInt()))
    elif val.kind == JFloat:
      this.placeHolder.add($(val.getFloat()))
    else:
      this.placeHolder.add(val.getStr())
    values.add("?")

  this.sqlString.add(&" ({columns}) VALUES ({values})")
  return this


proc insertValuesSql*(this: RDB, rows: openArray[JsonNode]): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.insertValuesSql(this, rows)
  # of "mysql":
  #   result = mysql_generator.insertValuesSql(this, rows)
  # of "postgres":
  #   result = postgres_generator.insertValuesSql(this, rows)
  var columns = ""
  var rowsCount = 0

  for key, value in rows[0]:
    if rowsCount > 0: columns.add(", ")
    rowsCount += 1
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
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.updateSql(this)
  # of "mysql":
  #   result = mysql_generator.updateSql(this)
  # of "postgres":
  #   result = postgres_generator.updateSql(this)
  this.sqlString.add("UPDATE")

  let table = this.query["table"].getStr()
  this.sqlString.add(&" {table} SET ")
  return this


proc updateValuesSql*(this: RDB, items:JsonNode): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.updateValuesSql(this, items)
  # of "mysql":
  #   result = mysql_generator.updateValuesSql(this, items)
  # of "postgres":
  #   result = postgres_generator.updateValuesSql(this, items)
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
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.deleteSql(this)
  # of "mysql":
  #   result = mysql_generator.deleteSql(this)
  # of "postgres":
  #   result = postgres_generator.deleteSql(this)
  this.sqlString.add("DELETE")
  return this


proc deleteByIdSql*(this: RDB, id: int, key: string): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.deleteByIdSql(this, key)
  # of "mysql":
  #   result = mysql_generator.deleteByIdSql(this, key)
  # of "postgres":
  #   result = postgres_generator.deleteByIdSql(this, key)
  this.sqlString.add(&" WHERE {key} = ?")
  return this

# ==================== Aggregates ====================

proc selectCountSql*(this: RDB): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectCountSql(this)
  # of "mysql":
  #   result = mysql_generator.selectCountSql(this)
  # of "postgres":
  #   result = postgres_generator.selectCountSql(this)
  this.sqlString = "SELECT count(*) as aggregate"
  return this


proc selectMaxSql*(this:RDB, column:string): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectMaxSql(this, column)
  # of "mysql":
  #   result = mysql_generator.selectMaxSql(this, column)
  # of "postgres":
  #   result = postgres_generator.selectMaxSql(this, column)
  this.sqlString = &"SELECT max({column}) as aggregate"
  return this


proc selectMinSql*(this:RDB, column:string): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectMinSql(this, column)
  # of "mysql":
  #   result = mysql_generator.selectMinSql(this, column)
  # of "postgres":
  #   result = postgres_generator.selectMinSql(this, column)
  this.sqlString = &"SELECT min({column}) as aggregate"
  return this


proc selectAvgSql*(this:RDB, column:string): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectAvgSql(this, column)
  # of "mysql":
  #   result = mysql_generator.selectAvgSql(this, column)
  # of "postgres":
  #   result = postgres_generator.selectAvgSql(this, column)
  this.sqlString = &"SELECT avg({column}) as aggregate"
  return this


proc selectSumSql*(this:RDB, column:string): RDB =
  # let driver = util.getDriver()
  # case driver:
  # of "sqlite":
  #   result = sqlite_generator.selectSumSql(this, column)
  # of "mysql":
  #   result = mysql_generator.selectSumSql(this, column)
  # of "postgres":
  #   result = postgres_generator.selectSumSql(this, column)
  this.sqlString = &"SELECT sum({column}) as aggregate"
  return this
