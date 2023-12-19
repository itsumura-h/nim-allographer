import std/json
import std/strformat
import std/strutils
# import ../../database_types
import ../mariadb_types


proc quote(input:string):string =
  ## "User.id as userId" => ```User```.```id``` as ```userId```
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"`{c[0]}` as `{c[1]}`")
    else:
      tmp.add(&"`{row}`")
  return tmp.join(".")


# ==================== SELECT ====================

proc selectSql*(self: MariadbQuery): MariadbQuery =
  var queryString = ""

  if self.query.hasKey("distinct"):
    queryString.add("SELECT DISTINCT")
  else:
    queryString.add("SELECT")

  if self.query.hasKey("select"):
    for i, item in self.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      if column != "*": column = quote(column)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  self.queryString = queryString
  return self


proc fromSql*(self: MariadbQuery): MariadbQuery =
  let table = self.query["table"].getStr()
  self.queryString.add(&" FROM `{table}`")
  return self


proc selectFirstSql*(self: MariadbQuery): MariadbQuery =
  self.queryString.add(" LIMIT 1")
  return self


proc selectByIdSql*(self: MariadbQuery, key:string): MariadbQuery =
  let key = key.quote()
  if self.queryString.contains("WHERE"):
    self.queryString.add(&" AND {key} = ? LIMIT 1")
  else:
    self.queryString.add(&" WHERE {key} = ? LIMIT 1")
  return self


proc joinSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("join"):
    for row in self.query["join"]:
      let table = row["table"].getStr().quote()
      let column1 = row["column1"].getStr().quote()
      let symbol = row["symbol"].getStr()
      let column2 = row["column2"].getStr().quote()

      self.queryString.add(&" INNER JOIN {table} ON {column1} {symbol} {column2}")
  return self


proc leftJoinSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("left_join"):
    for row in self.query["left_join"]:
      let table = row["table"].getStr().quote()
      let column1 = row["column1"].getStr().quote()
      let symbol = row["symbol"].getStr()
      let column2 = row["column2"].getStr().quote()

      self.queryString.add(&" LEFT JOIN {table} ON {column1} {symbol} {column2}")
  return self


proc whereSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where"):
    for i, row in self.query["where"].getElems():
      let column = row["column"].getStr().quote()
      let symbol = row["symbol"].getStr()
      # let value = row["value"].getStr()
      if i == 0:
        self.queryString.add(&" WHERE {column} {symbol} ?")
      else:
        self.queryString.add(&" AND {column} {symbol} ?")
  return self


proc orWhereSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("or_where"):
    for row in self.query["or_where"]:
      let column = row["column"].getStr().quote()
      let symbol = row["symbol"].getStr()
      # let value = row["value"].getStr()

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" OR {column} {symbol} ?")
      else:
        self.queryString.add(&" WHERE {column} {symbol} ?")
  return self


proc whereBetweenSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_between"):
    for row in self.query["where_between"]:
      let column = row["column"].getStr()
      # let start = row["width"][0].getFloat()
      # let stop = row["width"][1].getFloat()

      if self.queryString.contains("WHERE"):
        # self.queryString.add(&" AND `{column}` BETWEEN {start} AND {stop}")
        self.queryString.add(&" AND `{column}` BETWEEN ? AND ?")
      else:
        # self.queryString.add(&" WHERE `{column}` BETWEEN {start} AND {stop}")
        self.queryString.add(&" WHERE `{column}` BETWEEN ? AND ?")
  return self


proc whereBetweenStringSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_between_string"):
    for row in self.query["where_between_string"]:
      let column = row["column"].getStr()
      # let start = row["width"][0].getStr
      # let stop = row["width"][1].getStr

      if self.queryString.contains("WHERE"):
        # self.queryString.add(&" AND `{column}` BETWEEN '{start}' AND '{stop}'")
        self.queryString.add(&" AND `{column}` BETWEEN ? AND ?")
      else:
        # self.queryString.add(&" WHERE `{column}` BETWEEN '{start}' AND '{stop}'")
        self.queryString.add(&" WHERE `{column}` BETWEEN ? AND ?")
  return self


proc whereNotBetweenSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_not_between"):
    for row in self.query["where_not_between"]:
      let column = row["column"].getStr().quote()
      # let start = row["width"][0].getFloat()
      # let stop = row["width"][1].getFloat()

      if self.queryString.contains("WHERE"):
        # self.queryString.add(&" AND `{column}` NOT BETWEEN {start} AND {stop}")
        self.queryString.add(&" AND {column} NOT BETWEEN ? AND ?")
      else:
        # self.queryString.add(&" WHERE `{column}` NOT BETWEEN {start} AND {stop}")
        self.queryString.add(&" WHERE {column} NOT BETWEEN ? AND ?")
  return self


proc whereNotBetweenStringSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_not_between_string"):
    for row in self.query["where_not_between_string"]:
      let column = row["column"].getStr().quote()
      # let start = row["width"][0].getStr
      # let stop = row["width"][1].getStr

      if self.queryString.contains("WHERE"):
        # self.queryString.add(&" AND `{column}` NOT BETWEEN '{start}' AND '{stop}'")
        self.queryString.add(&" AND {column} NOT BETWEEN ? AND ?")
      else:
        # self.queryString.add(&" WHERE `{column}` NOT BETWEEN '{start}' AND '{stop}'")
        self.queryString.add(&" WHERE {column} NOT BETWEEN ? AND ?")
  return self


proc whereInSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_in"):
    var widthString = ""
    for row in self.query["where_in"]:
      let column = row["column"].getStr().quote()
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        widthString.add("?")

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} IN ({widthString})")
      else:
        self.queryString.add(&" WHERE {column} IN ({widthString})")
  return self


proc whereNotInSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_not_in"):
    var widthString = ""
    for row in self.query["where_not_in"]:
      let column = row["column"].getStr().quote()
      for i, val in row["width"].getElems():
        if i > 0: widthString.add(", ")
        widthString.add("?")

      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} NOT IN ({widthString})")
      else:
        self.queryString.add(&" WHERE {column} NOT IN ({widthString})")
  return self


proc whereNullSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("where_null"):
    for row in self.query["where_null"]:
      let column = row["column"].getStr().quote()
      let symbol = row["symbol"].getStr()
      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} {symbol} NULL")
      else:
        self.queryString.add(&" WHERE {column} {symbol} NULL")
  return self


proc groupBySql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("group_by"):
    for row in self.query["group_by"]:
      let column = row["column"].getStr().quote()
      if self.queryString.contains("GROUP BY"):
        self.queryString.add(&", {column}")
      else:
        self.queryString.add(&" GROUP BY {column}")
  return self


proc havingSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("having"):
    for i, row in self.query["having"].getElems():
      let column = row["column"].getStr().quote()
      let symbol = row["symbol"].getStr()
      # let value = row["value"].getStr()

      if i == 0:
        self.queryString.add(&" HAVING {column} {symbol} ?")
      else:
        self.queryString.add(&" AND {column} {symbol} ?")

  return self


proc orderBySql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("order_by"):
    for row in self.query["order_by"]:
      let column = row["column"].getStr().quote()
      let order = row["order"].getStr()

      if self.queryString.contains("ORDER BY"):
        self.queryString.add(&", {column} {order}")
      else:
        self.queryString.add(&" ORDER BY {column} {order}")
  return self


proc limitSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("limit"):
    let num = self.query["limit"].getInt()
    self.queryString.add(&" LIMIT {num}")

  return self


proc offsetSql*(self: MariadbQuery): MariadbQuery =
  if self.query.hasKey("offset"):
    let num = self.query["offset"].getInt()
    self.queryString.add(&" OFFSET {num}")

  return self


# ==================== INSERT ====================

proc insertSql*(self: MariadbQuery): MariadbQuery =
  let table = self.query["table"].getStr()
  self.queryString = &"INSERT INTO `{table}`"
  return self


proc insertValueSql*(self: MariadbQuery, items: JsonNode): MariadbQuery =
  var columns = ""
  var values = ""

  var i = 0
  for key, val in items.pairs:
    defer: i += 1
    if i > 0:
      columns.add(", ")
      values.add(", ")
    # If column name contains Upper letter, column name is covered by double quote
    columns.add(&"`{key}`")

    self.placeHolder.add(%*{"key":key, "value":val})
    values.add("?")

  self.queryString.add(&" ({columns}) VALUES ({values})")
  return self


proc insertValuesSql*(self: MariadbQuery, rows: openArray[JsonNode]): MariadbQuery =
  var columns = ""

  var i = 0
  for key, value in rows[0]:
    defer: i += 1
    if i > 0: columns.add(", ")
    # If column name contains Upper letter, column name is covered by double quote
    columns.add(&"`{key}`")

  var values = ""
  var valuesCount = 0
  for items in rows:
    var valueCount = 0
    var value = ""
    for key, val in items.pairs:
      defer: valueCount += 1
      if valueCount > 0: value.add(", ")

      self.placeHolder.add(%*{"key":key, "value":val})
      value.add("?")

    if valuesCount > 0: values.add(", ")
    valuesCount += 1
    values.add(&"({value})")

  self.queryString.add(&" ({columns}) VALUES {values}")
  return self


# ==================== UPDATE ====================

proc updateSql*(self: MariadbQuery): MariadbQuery =
  var queryString = ""
  queryString.add("UPDATE")

  var table = self.query["table"].getStr()
  queryString.add(&" `{table}` SET")
  self.queryString = queryString
  return self


proc updateValuesSql*(self: MariadbQuery, items:JsonNode): MariadbQuery =
  var value = ""
  let placeHolder = newJArray()

  var i = 0
  for key, val in items.pairs:
    defer: i += 1
    if i > 0: value.add(",")
    value.add(&" `{key}` = ?")
    placeHolder.add(%*{"key":key, "value":val})

  for row in self.placeHolder.items:
    placeHolder.add(row)

  self.placeHolder = placeHolder

  self.queryString.add(value)
  return self


# ==================== DELETE ====================

proc deleteSql*(self: MariadbQuery): MariadbQuery =
  self.queryString = "DELETE"
  return self


proc deleteByIdSql*(self: MariadbQuery, id: int, key: string): MariadbQuery =
  self.queryString.add(&" WHERE `{key}` = ?")
  return self

# ==================== Aggregates ====================

proc selectCountSql*(self: MariadbQuery): MariadbQuery =
  let queryString =
    if self.query.hasKey("select"):
      let column = self.query["select"][0].getStr
      &"`{column}`"
    else:
      "*"
  self.queryString = &"SELECT count({queryString}) as aggregate"
  return self


proc selectMaxSql*(self: MariadbQuery, column:string): MariadbQuery =
  self.queryString = &"SELECT max(`{column}`) as aggregate"
  return self


proc selectMinSql*(self: MariadbQuery, column:string): MariadbQuery =
  self.queryString = &"SELECT min(`{column}`) as aggregate"
  return self


proc selectAvgSql*(self: MariadbQuery, column:string): MariadbQuery =
  self.queryString = &"SELECT avg(`{column}`) as aggregate"
  return self


proc selectSumSql*(self: MariadbQuery, column:string): MariadbQuery =
  self.queryString = &"SELECT sum(`{column}`) as aggregate"
  return self
