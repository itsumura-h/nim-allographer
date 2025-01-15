import std/json
import std/strformat
import std/strutils
# import ../../database_types
import ../mysql_types


proc quote(input:string):string =
  ## "User.id as userId" => ```User```.```id``` as ```userId```
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
        tmp.add(&"{funcName}(`{columnName}`) as `{alias}`")
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

proc selectSql*(self: MysqlQuery): MysqlQuery =
  var queryString = ""

  if self.query.hasKey("distinct"):
    queryString.add("SELECT DISTINCT")
  else:
    queryString.add("SELECT")

  if self.query.hasKey("select"):
    for i, item in self.query["select"].getElems():
      if i > 0: queryString.add(",")
      var column = item.getStr()
      # if column.contains("as"):
      #   let original = column.split("as")[0].strip()
      #   let renamed = column.split("as")[1].strip()
      #   queryString.add(&" `{original}` as `{renamed}`")
      # else:
      #   queryString.add(&" `{column}`")
      column = quote(column)
      queryString.add(&" {column}")
  else:
    queryString.add(" *")

  self.queryString = queryString
  return self


proc fromSql*(self: MysqlQuery): MysqlQuery =
  let table = self.query["table"].getStr().quote()
  self.queryString.add(&" FROM {table}")
  return self


proc selectFirstSql*(self: MysqlQuery): MysqlQuery =
  self.queryString.add(" LIMIT 1")
  return self


proc selectByIdSql*(self: MysqlQuery, key:string): MysqlQuery =
  let key = key.quote()
  if self.queryString.contains("WHERE"):
    self.queryString.add(&" AND {key} = ? LIMIT 1")
  else:
    self.queryString.add(&" WHERE {key} = ? LIMIT 1")
  return self


proc joinSql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("join"):
    for row in self.query["join"]:
      let table = row["table"].getStr().quote()
      let column1 = row["column1"].getStr().quote()
      let symbol = row["symbol"].getStr()
      let column2 = row["column2"].getStr().quote()

      self.queryString.add(&" INNER JOIN {table} ON {column1} {symbol} {column2}")
  return self


proc leftJoinSql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("left_join"):
    for row in self.query["left_join"]:
      let table = row["table"].getStr().quote()
      let column1 = row["column1"].getStr().quote()
      let symbol = row["symbol"].getStr()
      let column2 = row["column2"].getStr().quote()

      self.queryString.add(&" LEFT JOIN {table} ON {column1} {symbol} {column2}")
  return self


proc whereSql*(self: MysqlQuery): MysqlQuery =
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


proc orWhereSql*(self: MysqlQuery): MysqlQuery =
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


proc whereBetweenSql*(self: MysqlQuery): MysqlQuery =
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


proc whereBetweenStringSql*(self: MysqlQuery): MysqlQuery =
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


proc whereNotBetweenSql*(self: MysqlQuery): MysqlQuery =
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


proc whereNotBetweenStringSql*(self: MysqlQuery): MysqlQuery =
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


proc whereInSql*(self: MysqlQuery): MysqlQuery =
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


proc whereNotInSql*(self: MysqlQuery): MysqlQuery =
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


proc whereNullSql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("where_null"):
    for row in self.query["where_null"]:
      let column = row["column"].getStr().quote()
      let symbol = row["symbol"].getStr()
      if self.queryString.contains("WHERE"):
        self.queryString.add(&" AND {column} {symbol} NULL")
      else:
        self.queryString.add(&" WHERE {column} {symbol} NULL")
  return self


proc groupBySql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("group_by"):
    for row in self.query["group_by"]:
      let column = row["column"].getStr().quote()
      if self.queryString.contains("GROUP BY"):
        self.queryString.add(&", {column}")
      else:
        self.queryString.add(&" GROUP BY {column}")
  return self


proc havingSql*(self: MysqlQuery): MysqlQuery =
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


proc orderBySql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("order_by"):
    for row in self.query["order_by"]:
      let column = row["column"].getStr().quote()
      let order = row["order"].getStr()

      if self.queryString.contains("ORDER BY"):
        self.queryString.add(&", {column} {order}")
      else:
        self.queryString.add(&" ORDER BY {column} {order}")
  return self


proc limitSql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("limit"):
    let num = self.query["limit"].getInt()
    self.queryString.add(&" LIMIT {num}")

  return self


proc offsetSql*(self: MysqlQuery): MysqlQuery =
  if self.query.hasKey("offset"):
    let num = self.query["offset"].getInt()
    self.queryString.add(&" OFFSET {num}")

  return self


# ==================== INSERT ====================

proc insertSql*(self: MysqlQuery): MysqlQuery =
  let table = self.query["table"].getStr()
  self.queryString = &"INSERT INTO `{table}`"
  return self


proc insertValueSql*(self: MysqlQuery, items: JsonNode): MysqlQuery =
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


proc insertValuesSql*(self: MysqlQuery, rows: openArray[JsonNode]): MysqlQuery =
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

proc updateSql*(self: MysqlQuery): MysqlQuery =
  var queryString = ""
  queryString.add("UPDATE")

  var table = self.query["table"].getStr()
  queryString.add(&" `{table}` SET")
  self.queryString = queryString
  return self


proc updateValuesSql*(self: MysqlQuery, items:JsonNode): MysqlQuery =
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

proc deleteSql*(self: MysqlQuery): MysqlQuery =
  self.queryString = "DELETE"
  return self


proc deleteByIdSql*(self: MysqlQuery, id: int, key: string): MysqlQuery =
  self.queryString.add(&" WHERE `{key}` = ?")
  return self

# ==================== Aggregates ====================

proc selectCountSql*(self: MysqlQuery): MysqlQuery =
  let queryString =
    if self.query.hasKey("select"):
      let column = self.query["select"][0].getStr
      &"`{column}`"
    else:
      "*"
  self.queryString = &"SELECT count({queryString}) as aggregate"
  return self


proc selectMaxSql*(self: MysqlQuery, column:string): MysqlQuery =
  self.queryString = &"SELECT max(`{column}`) as aggregate"
  return self


proc selectMinSql*(self: MysqlQuery, column:string): MysqlQuery =
  self.queryString = &"SELECT min(`{column}`) as aggregate"
  return self


proc selectAvgSql*(self: MysqlQuery, column:string): MysqlQuery =
  self.queryString = &"SELECT avg(`{column}`) as aggregate"
  return self


proc selectSumSql*(self: MysqlQuery, column:string): MysqlQuery =
  self.queryString = &"SELECT sum(`{column}`) as aggregate"
  return self
