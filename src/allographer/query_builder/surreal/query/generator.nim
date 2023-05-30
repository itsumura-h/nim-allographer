import std/json
import std/strformat
import std/strutils
# import ../databases/surreal_lib
import ../surreal_types
import ../surreal_utils


# ==================== SELECT ====================
proc selectSql*(self: SurrealDb): SurrealDb =
  var queryString = "SELECT"

  if self.query.hasKey("select"):
    for i, item in self.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      quoteColumn(column)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  self.queryString = queryString
  return self


proc fromSql*(self: SurrealDb): SurrealDb =
  var table = self.query["table"].getStr()
  quoteTable(table)
  self.queryString.add(&" FROM {table}")
  return self


proc selectFirstSql*(self:SurrealDb): SurrealDb =
  self.queryString.add(" LIMIT 1")
  return self


proc selectByIdSql*(self:SurrealDb, key:string): SurrealDb =
  var key = key
  quoteColumn(key)
  if self.queryString.contains("WHERE"):
    self.queryString.add(&" AND {key} = ? LIMIT 1")
  else:
    self.queryString.add(&" WHERE {key} = ? LIMIT 1")
  return self


proc whereSql*(self: SurrealDb): SurrealDb =
  if self.query.hasKey("where"):
    for i, row in self.query["where"].getElems():
      var column = row["column"].getStr()
      quoteColumn(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if i == 0:
        self.queryString.add(&" WHERE {column} {symbol} {value}")
      else:
        self.queryString.add(&" AND {column} {symbol} {value}")
  return self


proc orWhereSql*(self: SurrealDb): SurrealDb =
  if self.query.hasKey("or_where"):
    for row in self.query["or_where"]:
      var column = row["column"].getStr()
      quoteColumn(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"].getStr()

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" OR {column} {symbol} {value}")
      else:
        self.queryString.add(&" WHERE {column} {symbol} {value}")
  return self


proc groupBySql*(self:SurrealDb): SurrealDb =
  if self.query.hasKey("group_by"):
    for row in self.query["group_by"]:
      var column = row["column"].getStr()
      quoteColumn(column)
      if self.queryString.contains("GROUP BY"):
        self.queryString.add(&", {column}")
      else:
        self.queryString.add(&" GROUP BY {column}")
  return self


proc orderBySql*(self:SurrealDb): SurrealDb =
  if self.query.hasKey("order_by"):
    for row in self.query["order_by"]:
      var column = row["column"].getStr()
      quoteColumn(column)
      let collation = row["collation"].getStr()
      let order = row["order"].getStr()

      if self.queryString.contains("ORDER BY"):
        self.queryString.add(&", {column} {collation} {order}")
      else:
        self.queryString.add(&" ORDER BY {column} {collation} {order}")
  return self


proc limitSql*(self: SurrealDb): SurrealDb =
  if self.query.hasKey("limit"):
    var num = self.query["limit"].getInt()
    self.queryString.add(&" LIMIT {num}")
  return self


proc startSql*(self: SurrealDb): SurrealDb =
  if self.query.hasKey("start"):
    var num = self.query["start"].getInt()
    self.queryString.add(&" START {num}")
  return self


proc fetchSql*(self:SurrealDb):SurrealDb =
  if self.query.hasKey("fetch"):
    self.queryString.add(" FETCH")
    for i, item in self.query["fetch"].getElems():
      if i > 0: self.queryString.add(",")
      var column = item.getStr()
      quoteColumn(column)
      self.queryString.add(&" {column}")
  return self


proc parallelSql*(self:SurrealDb):SurrealDb =
  if self.query.hasKey("parallel") and self.query["parallel"].getBool():
    self.queryString.add(" PARALLEL")
  return self


# ==================== INSERT ====================

proc insertSql*(self: SurrealDb): SurrealDb =
  var table = self.query["table"].getStr()
  quoteTable(table)
  self.queryString = &"INSERT INTO {table}"
  return self


proc insertValueSql*(self: SurrealDb, items: JsonNode): SurrealDb =
  self.queryString.add(" " & $items)
  return self


proc insertValuesSql*(self: SurrealDb, rows: openArray[JsonNode]): SurrealDb =
  var query = " ["
  for i, row in rows:
    if i > 0: query.add(", ")
    query.add($row)
  query.add("]")
  self.queryString.add(query)
  return self


# proc insertValuesSql*(self: SurrealDb, rows: openArray[JsonNode]): SurrealDb =
#   var columns = ""

#   var i = 0
#   for key, value in rows[0]:
#     if i > 0: columns.add(", ")
#     i += 1
#     # If column name contains Upper letter, column name is covered by double quote
#     var key = key
#     quoteColumn(key)
#     columns.add(key)

#   var values = ""
#   var valuesCount = 0
#   for items in rows:
#     var valueCount = 0
#     var value = ""
#     for key, val in items.pairs:
#       if valueCount > 0: value.add(", ")
#       valueCount += 1
#       if val.kind == JInt:
#         self.placeHolder.add($(val.getInt()))
#       elif val.kind == JFloat:
#         self.placeHolder.add($(val.getFloat()))
#       elif val.kind == JBool:
#         let val =
#           if val.getBool():
#             1
#           else:
#             0
#         self.placeHolder.add($val)
#       elif val.kind == JObject:
#         self.placeHolder.add($val)
#       elif val.kind == JNull:
#         self.placeHolder.add("null")
#       else:
#         self.placeHolder.add(val.getStr())
#       value.add("?")

#     if valuesCount > 0: values.add(", ")
#     valuesCount += 1
#     values.add(&"({value})")

#   self.queryString.add(&" ({columns}) VALUES {values}")
#   return self
