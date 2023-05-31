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


# ==================== UPDATE ====================

proc updateSql*(self: SurrealDb): SurrealDb =
  var queryString = ""
  queryString.add("UPDATE")

  var table = self.query["table"].getStr()
  quoteTable(table)
  queryString.add(&" {table} SET ")
  self.queryString = queryString
  return self


proc updateValuesSql*(self: SurrealDb, items:JsonNode): SurrealDb =
  var value = ""

  var i = 0
  for key, val in items.pairs:
    if i > 0: value.add(", ")
    i += 1
    var key = key
    quoteColumn(key)
    value.add(&"{key} = ?")

  self.queryString.add(value)
  return self


proc updateMergeSql*(self: SurrealDb, id:string, items:JsonNode):SurrealDb =
  self.queryString = &"UPDATE {id} MERGE {items}"
  return self


# ==================== DELETE ====================

proc deleteSql*(self: SurrealDb): SurrealDb =
  self.queryString = "DELETE"
  return self


proc deleteByIdSql*(self: SurrealDb, id: string): SurrealDb =
  self.queryString.add(&" {id}")
  return self
