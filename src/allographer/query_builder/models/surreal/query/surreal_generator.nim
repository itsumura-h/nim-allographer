import std/json
import std/strformat
import std/strutils
# import ../databases/surreal_lib
import ../surreal_types


# proc quoteTable*(input:var string) =
#   input = &"`{input}`"

proc quote*(input:string):string =
  ## "User.id as userId" => `User`.`id`  as `userId`
  ##
  ## "count(id) as count" => count(`id`) as `count`
  ##
  ## "math::max(id) as maxId" => math::max(`id`) as `maxId`
  ##
  var tmp = newSeq[string]()
  for segment in input.split("."):
    if segment.contains(" as "):
      # Split once on ' as ' to separate the expression and its alias
      let parts = segment.split(" as ", maxsplit = 1)
      let expression = parts[0]
      let alias = parts[1]
      if expression.contains("("):
        # Extract function name and column name using index-based slicing
        let funcStart = expression.find('(')
        let funcEnd = expression.find(')', funcStart)
        let funcName = expression[0 ..< funcStart]
        let columnName = expression[funcStart + 1 ..< funcEnd]

        if columnName.len > 0:
          tmp.add(&"{funcName}(`{columnName}`) as `{alias}`")
        else:
          tmp.add(&"{funcName}() as `{alias}`")
      else:
        # Quote the expression and alias
        tmp.add(&"`{expression}` as `{alias}`")
    elif segment.contains("("):
      # Leave functions without alias as is
      tmp.add(segment)
    else:
      # Quote standalone identifiers
      tmp.add(&"`{segment}`")
  return tmp.join(".")


# ==================== SELECT ====================
proc selectSql*(self: SurrealQuery): SurrealQuery =
  var queryString = "SELECT"

  if self.query.hasKey("select"):
    for i, item in self.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      column = quote(column)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  self.queryString = queryString
  return self


proc fromSql*(self: SurrealQuery): SurrealQuery =
  var table = self.query["table"].getStr()
  table = quote(table)
  self.queryString.add(&" FROM {table}")
  return self


proc maxFromSql*(self:SurrealQuery, column:string):SurrealQuery =
  var table = self.query["table"].getStr()
  table = quote(table)
  self.queryString.add(&" FROM array::max({column})")
  return self


proc selectFirstSql*(self:SurrealQuery): SurrealQuery =
  self.queryString.add(" LIMIT 1")
  return self


proc selectByIdSql*(self:SurrealQuery, id:SurrealId, key:string): SurrealQuery =
  var key = key
  key = quote(key)
  if self.queryString.contains("WHERE"):
    self.queryString.add(&" AND {key} = ? LIMIT 1")
    self.placeHolder.add(%id.rawId)
  else:
    self.queryString.add(&" WHERE {key} = ? LIMIT 1")
    self.placeHolder.add(%id.rawId)
  return self


proc whereSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("where"):
    for i, row in self.query["where"].getElems():
      var column = row["column"].getStr()
      column = quote(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"]

      if i == 0:
        self.queryString.add(&" WHERE {column} {symbol} ?")
        self.placeHolder.add(value)
      else:
        self.queryString.add(&" AND {column} {symbol} ?")
        self.placeHolder.add(value)
  return self


proc orWhereSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("or_where"):
    for row in self.query["or_where"]:
      var column = row["column"].getStr()
      column = quote(column)
      var symbol = row["symbol"].getStr()
      var value = row["value"]

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" OR {column} {symbol} ?")
        self.placeHolder.add(value)
      else:
        self.queryString.add(&" WHERE {column} {symbol} ?")
        self.placeHolder.add(value)
  return self


proc whereBetweenSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("where_between"):
    for row in self.query["where_between"]:
      var column = row["column"].getStr()
      column = quote(column)

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND ? <= {column} AND {column} <= ?")
      else:
        self.queryString.add(&" WHERE ? <= {column} AND {column} <= ?")

      self.placeHolder.add(row["width"][0])
      self.placeHolder.add(row["width"][1])

  return self


proc whereNotBetweenSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("where_not_between"):
    for row in self.query["where_not_between"]:
      var column = row["column"].getStr()
      column = quote(column)

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND ? > {column} AND {column} < ?")
      else:
        self.queryString.add(&" WHERE ? > {column} AND {column} < ?")

      self.placeHolder.add(row["width"][0])
      self.placeHolder.add(row["width"][1])

  return self


proc whereInSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("where_in"):
    for row in self.query["where_in"]:
      var column = row["column"].getStr()
      column = quote(column)

      var values = ""
      var i = 0
      for row in row["width"].items:
        defer: i.inc()
        if i > 0: values.add(", ")
        values.add("?")
        self.placeHolder.add(row)
      values.add("")

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND [{values}] CONTAINS {column}")
      else:
        self.queryString.add(&" WHERE [{values}] CONTAINS {column}")

  return self


proc whereNotInSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("where_not_in"):
    for row in self.query["where_not_in"]:
      var column = row["column"].getStr()
      column = quote(column)

      var values = ""
      var i = 0
      for row in row["width"].items:
        defer: i.inc()
        if i > 0: values.add(", ")
        values.add("?")
        self.placeHolder.add(row)
      values.add("")

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND [{values}] CONTAINSNOT {column}")
      else:
        self.queryString.add(&" WHERE [{values}] CONTAINSNOT {column}")

  return self


proc whereNullSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("where_null"):
    for row in self.query["where_null"]:
      var column = row["column"].getStr()
      column = quote(column)

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" OR {column} IS NULL")
      else:
        self.queryString.add(&" WHERE {column} IS NULL")

  return self


proc groupBySql*(self:SurrealQuery): SurrealQuery =
  if self.query.hasKey("group_by"):
    for row in self.query["group_by"]:
      var column = row["column"].getStr()
      column = quote(column)
      if self.queryString.contains("GROUP BY"):
        self.queryString.add(&", {column}")
      else:
        self.queryString.add(&" GROUP BY {column}")
  return self


proc orderBySql*(self:SurrealQuery): SurrealQuery =
  if self.query.hasKey("order_by"):
    for row in self.query["order_by"]:
      var column = row["column"].getStr()
      column = quote(column)
      let collation = row["collation"].getStr()
      let order = row["order"].getStr()

      if self.queryString.contains("ORDER BY"):
        self.queryString.add(&", {column} {collation} {order}")
      else:
        self.queryString.add(&" ORDER BY {column} {collation} {order}")
  return self


proc limitSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("limit"):
    var num = self.query["limit"].getInt()
    self.queryString.add(&" LIMIT {num}")
  return self


proc startSql*(self: SurrealQuery): SurrealQuery =
  if self.query.hasKey("start"):
    var num = self.query["start"].getInt()
    self.queryString.add(&" START {num}")
  return self


proc fetchSql*(self:SurrealQuery):SurrealQuery =
  if self.query.hasKey("fetch"):
    self.queryString.add(" FETCH")
    for i, item in self.query["fetch"].getElems():
      if i > 0: self.queryString.add(",")
      var column = item.getStr()
      column = quote(column)
      self.queryString.add(&" {column}")
  return self


proc parallelSql*(self:SurrealQuery):SurrealQuery =
  if self.query.hasKey("parallel") and self.query["parallel"].getBool():
    self.queryString.add(" PARALLEL")
  return self


# ==================== INSERT ====================

proc insertSql*(self: SurrealQuery): SurrealQuery =
  var table = self.query["table"].getStr()
  table = quote(table)
  self.queryString = &"INSERT INTO {table}"
  return self


proc insertValueSql*(self: SurrealQuery, items: JsonNode): SurrealQuery =
  self.queryString.add(" {")
  var i = 0
  for (key, item) in items.pairs:
    defer: i.inc()
    if i > 0: self.queryString.add(", ")
    self.queryString.add(&"{key}: ?")
    self.placeHolder.add(item)
  self.queryString.add("}")
  return self


proc insertValuesSql*(self: SurrealQuery, rows: openArray[JsonNode]): SurrealQuery =
  self.queryString.add(" [")
  for i, row in rows:
    if i > 0: self.queryString.add(", ")
    var j = 0
    self.queryString.add("{")
    for (key, item) in row.pairs:
      defer: j.inc()
      if j > 0: self.queryString.add(", ")
      self.queryString.add(&"{key}: ?")
      self.placeHolder.add(item)
    self.queryString.add("}")
  self.queryString.add("]")
  return self


# ==================== UPDATE ====================

proc updateSql*(self: SurrealQuery): SurrealQuery =
  var queryString = ""
  queryString.add("UPDATE")

  var table = self.query["table"].getStr()
  table = quote(table)
  queryString.add(&" {table} SET ")
  self.queryString = queryString
  return self


proc updateValuesSql*(self: SurrealQuery, items:JsonNode): SurrealQuery =
  var i = 0
  for key, val in items.pairs:
    defer: i.inc()
    if i > 0: self.queryString.add(", ")
    self.queryString.add(&"{key} = ?")
    self.placeHolder.add(val)

  return self


proc updateMergeSql*(self: SurrealQuery, id:string, items:JsonNode):SurrealQuery =
  self.queryString = &"UPDATE {id} MERGE {items}"
  return self


# ==================== DELETE ====================

proc deleteSql*(self: SurrealQuery): SurrealQuery =
  self.queryString = "DELETE"
  return self


proc deleteByIdSql*(self: SurrealQuery, id: string): SurrealQuery =
  self.queryString.add(&" ?")
  self.placeHolder.add(%id)
  return self


# ==================== Aggregates ====================

proc selectCountSql*(self: SurrealQuery): SurrealQuery =
  var queryString =
    if self.query.hasKey("select"):
      var column = self.query["select"][0].getStr
      column = quote(column)
      &"{column}"
    else:
      ""
  self.queryString = &"SELECT count({queryString}) AS total"
  return self


proc selectAvgSql*(self: SurrealQuery, column:string): SurrealQuery =
  var column = column
  column = quote(column)
  self.queryString = &"SELECT math::trimean({column}) AS avg"
  return self


proc selectSumSql*(self: SurrealQuery, column:string): SurrealQuery =
  var column = column
  column = quote(column)
  self.queryString = &"SELECT math::sum({column}) AS sum"
  return self


proc groupAllSql*(self: SurrealQuery):SurrealQuery =
  self.queryString.add(" GROUP ALL")
  return self
