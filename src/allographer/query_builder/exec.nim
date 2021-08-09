import json, strutils, strformat, algorithm, options, asyncdispatch
import base, builders
import ../utils
import ../async/async_db


proc selectSql*(self: Rdb):string =
  result = self.selectBuilder().sqlString & $self.placeHolder
  echo result

proc getColumns(driver:Driver, db_columns:DbColumns):seq[array[3, string]] =
  var columns = newSeq[array[3, string]](db_columns.len)
  for i, row in db_columns:
    case driver:
    of SQLite3:
      columns[i] = [row.name, row.typ.name, $row.typ.size]
    of MySQL, MariaDB:
      columns[i] = [row.name, $row.typ.kind, $row.typ.size]
    of PostgreSQL:
      columns[i] = [row.name, $row.typ.kind, $row.typ.size]
  return columns

proc toJson(driver:Driver, results:openArray[seq[string]], columns:openArray[array[3, string]]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  for index, rows in results.pairs:
    var response_row = newJObject()
    for i, row in rows:
      let key = columns[i][0]
      let typ = columns[i][1]
      let size = columns[i][2]

      case driver:
      of SQLite3:
        if row == "":
          response_row[key] = newJNull()
        elif ["INTEGER", "INT", "SMALLINT", "MEDIUMINT", "BIGINT"].contains(typ):
          response_row[key] = newJInt(row.parseInt)
        elif ["NUMERIC", "DECIMAL", "DOUBLE"].contains(typ):
          response_row[key] = newJFloat(row.parseFloat)
        elif ["TINYINT", "BOOLEAN"].contains(typ):
          response_row[key] = newJBool(row.parseBool)
        else:
          response_row[key] = newJString(row)
      of MySQL, MariaDB:
        if row == "":
          response_row[key] = newJNull()
        elif [$dbInt, $dbUInt].contains(typ) and size == "1":
          if row == "0":
            response_row[key] = newJBool(false)
          elif row == "1":
            response_row[key] = newJBool(true)
        elif [$dbInt, $dbUInt].contains(typ):
          response_row[key] = newJInt(row.parseInt)
        elif [$dbDecimal, $dbFloat].contains(typ):
          response_row[key] = newJFloat(row.parseFloat)
        elif [$dbJson].contains(typ):
          response_row[key] = row.parseJson
        else:
          response_row[key] = newJString(row)
      of PostgreSQL:
        if row == "":
          response_row[key] = newJNull()
        elif [$dbInt, $dbUInt].contains(typ):
          response_row[key] = newJInt(row.parseInt)
        elif [$dbDecimal, $dbFloat].contains(typ):
          response_row[key] = newJFloat(row.parseFloat)
        elif [$dbBool].contains(typ):
          if row == "f":
            response_row[key] = newJBool(false)
          elif row == "t":
            response_row[key] = newJBool(true)
        elif [$dbJson].contains(typ):
          response_row[key] = row.parseJson
        else:
          response_row[key] = newJString(row)

    response_table[index] = response_row
  return response_table

proc getAllRows(self:Connections, sqlString:string, args:seq[string]):Future[seq[JsonNode]] {.async.} =
  let (rows, dbColumns) = await self.query(sqlString, args)

  if rows.len == 0:
    echoErrorMsg(sqlString & $args)
    return newSeq[JsonNode](0)

  let columns = getColumns(self.driver, dbColumns)
  return toJson(self.driver, rows, columns) # seq[JsonNode]

proc getAllRowsPlain*(db:Connections, sqlString:string, args:seq[string]):Future[seq[seq[string]]] {.async.} =
  let (rows, _)  = await db.query(sqlString, args)
  return rows

proc getRow(self:Connections, sqlString:string, args:seq[string]):Future[Option[JsonNode]] {.async.} =
  let (rows, dbColumns) = await self.query(sqlString, args)

  if rows.len == 0:
    echoErrorMsg(sqlString & $args)
    return none(JsonNode)

  let columns = getColumns(self.driver, dbColumns)
  return toJson(self.driver, rows, columns)[0].some

proc getRowPlain(self:Connections, sqlString:string, args:seq[string]):Future[seq[string]] {.async.} =
  let (rows, _) = await self.query(sqlString, args)
  return rows[0]

proc orm(rows:openArray[JsonNode], typ:typedesc):seq[typ.type] =
  var response = newSeq[typ.type](rows.len)
  for i, row in rows:
    response[i] = row.to(typ.type)
  return response

proc orm(row:JsonNode, typ:typedesc):typ.type =
  return row.to(typ)

# =============================================================================

proc toSql*(self: Rdb): string =
  self.sqlString = self.selectBuilder().sqlString
  return self.sqlString

proc get*(self: Rdb):Future[seq[JsonNode]] {.async.} =
  defer: self.cleanUp()
  self.sqlString = self.selectBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getAllRows(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc get*(self: Rdb, typ: typedesc): Future[seq[typ.type]] {.async.} =
  defer: self.cleanUp()
  self.sqlString = self.selectBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getAllRows(self.db, self.sqlString, self.placeHolder).orm(typ)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[typ.type](0)

proc getPlain*(self:Rdb):Future[seq[seq[string]]] {.async.} =
  defer: self.cleanUp()
  self.sqlString = self.selectBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getAllRowsPlain(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[seq[string]](0)

proc getRaw*(self: Rdb):Future[seq[JsonNode]]{.async.} =
  defer: self.cleanUp()
  try:
    logger(self.sqlString, self.placeHolder)
    return await getAllRows(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc getRaw*(self: Rdb, typ: typedesc):Future[seq[typ.type]]{.async.} =
  defer: self.cleanUp()
  try:
    logger(self.sqlString, self.placeHolder)
    return await getAllRows(self.db, self.sqlString, self.placeHolder).orm(typ)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[typ.type](0)

proc first*(self: Rdb):Future[Option[JsonNode]] {.async.} =
  defer: self.cleanUp()
  self.sqlString = self.selectFirstBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getRow(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(JsonNode)

proc first*(self: Rdb, typ: typedesc):Future[Option[typ.type]] =
  defer: self.cleanUp()
  self.sqlString = self.selectFirstBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getRow(self.db, self.sqlString, self.placeHolder).get.orm(typ).some
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(typ.type)

proc firstPlain*(self: Rdb):Future[seq[string]]{.async.} =
  defer: self.cleanUp()
  self.sqlString = self.selectFirstBuilder().sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getRowPlain(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[string](0)

proc find*(self: Rdb, id: int, key="id"):Future[Option[JsonNode]]{.async.} =
  defer: self.cleanUp()
  self.placeHolder.add($id)
  self.sqlString = self.selectFindBuilder(id, key).sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getRow(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(JsonNode)

proc find*(self: Rdb, id: int, typ:typedesc, key="id"):Future[Option[typ.type]]{.async.} =
  defer: self.cleanUp()
  self.placeHolder.add($id)
  self.sqlString = self.selectFindBuilder(id, key).sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getRow(self.db, self.sqlString, self.placeHolder).get.orm(typ).some
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(typ.type)

proc findPlain*(self:Rdb, id:int, key="id"):Future[seq[string]]{.async.} =
  defer: self.cleanUp()
  self.placeHolder.add($id)
  self.sqlString = self.selectFindBuilder(id, key).sqlString
  try:
    logger(self.sqlString, self.placeHolder)
    return await getRowPlain(self.db, self.sqlString, self.placeHolder)
  except Exception:
    echoErrorMsg(self.sqlString & $self.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[string](0)


# ==================== INSERT ====================

proc insertSql*(self: Rdb, items: JsonNode):string =
  result = self.insertValueBuilder(items).sqlString & $self.placeHolder
  echo result

proc insertId(db:Connections, sqlString:string, placeHolder:seq[string], key:string):Future[int]{.async.} =
  if db.driver == SQLite3:
    await db.exec(sqlString, placeHolder)
    let (rows, _) = await db.query("SELECT last_insert_rowid()")
    return rows[0][0].parseInt
  else:
    var key = key
    wrapUpper(key, db.driver)
    var sqlString = sqlString
    sqlString.add(&" RETURNING {key}")
    logger(sqlString, placeHolder)
    let (rows, _) = await db.query(sqlString, placeHolder)
    return rows[0][0].parseInt

proc insert*(self: Rdb, items: JsonNode){.async.} =
  defer: self.cleanUp()
  self.sqlString = self.insertValueBuilder(items).sqlString
  logger(self.sqlString, self.placeHolder)
  await self.db.exec(self.sqlString, self.placeHolder)

proc insert*(self: Rdb, rows: seq[JsonNode]){.async.} =
  defer: self.cleanUp()
  self.sqlString = self.insertValuesBuilder(rows).sqlString
  logger(self.sqlString, self.placeHolder)
  await self.db.exec(self.sqlString, self.placeHolder)

proc inserts*(self: Rdb, rows: seq[JsonNode]){.async.} =
  defer: self.cleanUp()
  for row in rows:
    let sqlString = self.insertValueBuilder(row).sqlString
    logger(sqlString, self.placeHolder)
    await self.db.exec(sqlString, self.placeHolder)
    self.placeHolder = @[]

proc insertID*(self: Rdb, items: JsonNode, key="id"):Future[int] {.async.} =
  defer: self.cleanUp()
  self.sqlString = self.insertValueBuilder(items).sqlString
  return await self.db.insertID(self.sqlString, self.placeHolder, key)

proc insertID*(self: Rdb, rows: seq[JsonNode], key="id"):Future[int] {.async.} =
  defer: self.cleanUp()
  self.sqlString = self.insertValuesBuilder(rows).sqlString
  result = await self.db.insertID(self.sqlString, self.placeHolder, key)
  self.placeHolder = @[]

proc insertsID*(self: Rdb, rows: seq[JsonNode], key="id"):Future[seq[int]]{.async.} =
  defer: self.cleanUp()
  var response = newSeq[int](rows.len)
  for i, row in rows:
    let sqlString = self.insertValueBuilder(row).sqlString
    response[i] = await self.db.insertID(sqlString, self.placeHolder, key)
    self.placeHolder = @[]
  return response

# ==================== UPDATE ====================

proc updateSql*(self: Rdb, items: JsonNode):string =
  defer: self.cleanUp()
  var updatePlaceHolder: seq[string]
  for item in items.pairs:
    if item.val.kind == JInt:
      updatePlaceHolder.add($(item.val.getInt()))
    elif item.val.kind == JFloat:
      updatePlaceHolder.add($(item.val.getFloat()))
    elif [JObject, JArray].contains(item.val.kind):
      updatePlaceHolder.add($(item.val))
    else:
      updatePlaceHolder.add(item.val.getStr())

  let placeHolder = updatePlaceHolder & self.placeHolder
  let sqlString = self.updateBuilder(items).sqlString

  result = sqlString & $placeHolder
  echo result

proc update*(self: Rdb, items: JsonNode){.async.} =
  defer: self.cleanUp()
  var updatePlaceHolder: seq[string]
  for item in items.pairs:
    if item.val.kind == JInt:
      updatePlaceHolder.add($(item.val.getInt()))
    elif item.val.kind == JFloat:
      updatePlaceHolder.add($(item.val.getFloat()))
    elif item.val.kind == JBool:
      updatePlaceHolder.add($(item.val.getBool()))
    elif [JObject, JArray].contains(item.val.kind):
      updatePlaceHolder.add($(item.val))
    else:
      updatePlaceHolder.add(item.val.getStr())

  self.placeHolder = updatePlaceHolder & self.placeHolder
  self.sqlString = self.updateBuilder(items).sqlString

  logger(self.sqlString, self.placeHolder)
  await self.db.exec(self.sqlString, self.placeHolder)

# ==================== DELETE ====================

proc deleteSql*(self: Rdb):string =
  result = self.deleteBuilder().sqlString & $self.placeHolder
  echo result

proc delete*(self: Rdb){.async.} =
  defer: self.cleanUp()
  self.sqlString = self.deleteBuilder().sqlString
  logger(self.sqlString, self.placeHolder)
  await self.db.exec(self.sqlString, self.placeHolder)

proc delete*(self: Rdb, id: int, key="id"){.async.} =
  defer: self.cleanUp()
  self.placeHolder.add($id)
  self.sqlString = self.deleteByIdBuilder(id, key).sqlString
  logger(self.sqlString, self.placeHolder)
  await self.db.exec(self.sqlString, self.placeHolder)

# ==================== EXEC ====================

proc exec*(self: Rdb){.async.} =
  ## It is only used with raw()
  defer: self.cleanUp()
  logger(self.sqlString, self.placeHolder)
  await self.db.exec(self.sqlString, self.placeHolder)


# ==================== Aggregates ====================

proc count*(self:Rdb):Future[int]{.async.} =
  self.sqlString = self.countBuilder().sqlString
  logger(self.sqlString, self.placeHolder)
  let response =  await self.db.getRow(self.sqlString, self.placeHolder)
  if response.isSome:
    case self.db.driver
    of SQLite3:
      return response.get["aggregate"].getStr().parseInt()
    of MySQL, MariaDB:
      return response.get["aggregate"].getInt()
    of PostgreSQL:
      return response.get["aggregate"].getInt()
  else:
    return 0

proc max*(self:Rdb, column:string):Future[Option[string]]{.async.} =
  self.sqlString = self.maxBuilder(column).sqlString
  logger(self.sqlString, self.placeHolder)
  let response =  await self.db.getRow(self.sqlString, self.placeHolder)
  if response.isSome:
    case response.get["aggregate"].kind
    of JInt:
      return some($(response.get["aggregate"].getInt))
    of JFloat:
      return some($(response.get["aggregate"].getFloat))
    else:
      return some(response.get["aggregate"].getStr)
  else:
    return none(string)

proc min*(self:Rdb, column:string):Future[Option[string]]{.async.} =
  self.sqlString = self.minBuilder(column).sqlString
  logger(self.sqlString, self.placeHolder)
  let response =  await self.db.getRow(self.sqlString, self.placeHolder)
  if response.isSome:
    case response.get["aggregate"].kind
    of JInt:
      return some($(response.get["aggregate"].getInt))
    of JFloat:
      return some($(response.get["aggregate"].getFloat))
    else:
      return some(response.get["aggregate"].getStr)
  else:
    return none(string)

proc avg*(self:Rdb, column:string):Future[Option[float]]{.async.} =
  self.sqlString = self.avgBuilder(column).sqlString
  logger(self.sqlString, self.placeHolder)
  let response =  await self.db.getRow(self.sqlString, self.placeHolder)
  if response.isSome:
    case self.db.driver
    of SQLite3:
      return response.get["aggregate"].getStr().parseFloat.some
    else:
      return response.get["aggregate"].getFloat.some
  else:
    return none(float)

proc sum*(self:Rdb, column:string):Future[Option[float]]{.async.} =
  self.sqlString = self.sumBuilder(column).sqlString
  logger(self.sqlString, self.placeHolder)
  let response = await self.db.getRow(self.sqlString, self.placeHolder)
  if response.isSome:
    case self.db.driver
    of SQLite3:
      return response.get["aggregate"].getStr.parseFloat.some
    else:
      return response.get["aggregate"].getFloat.some
  else:
    return none(float)


# ==================== Paginate ====================

from grammars import where, limit, offset, orderBy, Order

proc paginate*(self:Rdb, display:int, page:int=1):Future[JsonNode]{.async.} =
  if not page > 0: raise newException(Exception, "Arg page should be larger than 0")
  let total = await self.count()
  let offset = (page - 1) * display
  let currentPage = await self.limit(display).offset(offset).get()
  let count = currentPage.len()
  let hasMorePages = if page * display < total: true else: false
  let lastPage = int(total / display)
  let nextPage = if page + 1 <= lastPage: page + 1 else: lastPage
  let perPage = display
  let previousPage = if page - 1 > 0: page - 1 else: 1
  return %*{
    "count": count,
    "currentPage": currentPage,
    "hasMorePages": hasMorePages,
    "lastPage": lastPage,
    "nextPage": nextPage,
    "perPage": perPage,
    "previousPage": previousPage,
    "total": total
  }


proc getFirstItem(self:Rdb, keyArg:string, order:Order=Asc):Future[int]{.async.} =
  var sqlString = self.sqlString
  if order == Asc:
    sqlString = &"{sqlString} ORDER BY {keyArg} ASC LIMIT 1"
  else:
    sqlString = &"{sqlString} ORDER BY {keyArg} DESC LIMIT 1"
  let row = await self.db.getRow(sqlString, self.placeHolder)
  let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
  if row.isSome:
    return row.get[key].getInt
  else:
    return 0


proc getLastItem(self:Rdb, keyArg:string, order:Order=Asc):Future[int]{.async.} =
  var sqlString = self.sqlString
  if order == Asc:
    sqlString = &"{sqlString} ORDER BY {keyArg} DESC LIMIT 1"
  else:
    sqlString = &"{sqlString} ORDER BY {keyArg} ASC LIMIT 1"
  let row = await self.db.getRow(sqlString, self.placeHolder)
  let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
  if row.isSome:
    return row.get[key].getInt
  else:
    return 0


proc fastPaginate*(self:Rdb, display:int, key="id", order:Order=Asc):Future[JsonNode]{.async.} =
  self.sqlString = @[self.selectBuilder().sqlString][0]
  if order == Asc:
    self.sqlString = &"{self.sqlString} ORDER BY {key} ASC LIMIT {display + 1}"
  else:
    self.sqlString = &"{self.sqlString} ORDER BY {key} DESC LIMIT {display + 1}"
  logger(self.sqlString, self.placeHolder)
  var currentPage = await self.db.getAllRows(self.sqlString, self.placeHolder)
  if currentPage.len > 0:
    let newKey = if key.contains("."): key.split(".")[1] else: key
    let nextId = currentPage[currentPage.len-1][newKey].getInt()
    var hasNextId = true
    if currentPage.len > display:
      discard currentPage.pop()
    else:
      hasNextId = false
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": nextId,
      "hasNextId": hasNextId
    }
  else:
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": 0,
      "hasNextId": false
    }


proc fastPaginateNext*(self:Rdb, display, id:int, key="id", order:Order=Asc):Future[JsonNode]{.async.} =
  if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
  self.sqlString = @[self.selectBuilder().sqlString][0]
  let firstItem = await getFirstItem(self, key, order)

  let where = if self.sqlString.contains("WHERE"): "AND" else: "WHERE"
  if order == Asc:
    self.sqlString = &"""
SELECT * FROM (
  {self.sqlString} {where} {key} < {id} ORDER BY {key} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {self.sqlString} {where} {key} >= {id} ORDER BY {key} ASC LIMIT {display+1}
) x
"""
  else:
    self.sqlString = &"""
SELECT * FROM (
  {self.sqlString} {where} {key} > {id} ORDER BY {key} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {self.sqlString} {where} {key} <= {id} ORDER BY {key} DESC LIMIT {display+1}
) x
"""
  self.placeHolder &= self.placeHolder
  logger(self.sqlString, self.placeHolder)
  var currentPage = await self.db.getAllRows(self.sqlString, self.placeHolder)
  if currentPage.len > 0:
    let newKey = if key.contains("."): key.split(".")[1] else: key
    # previous
    var previousId = currentPage[0][newKey].getInt()
    var hasPreviousId = true
    if previousId != firstItem:
      currentPage.delete(0)
    else:
      hasPreviousId = false
    # next
    var nextId = currentPage[currentPage.len-1][newKey].getInt()
    var hasNextId = true
    if currentPage.len > display:
      discard currentPage.pop()
    else:
      hasNextId = false

    return %*{
      "previousId": previousId,
      "hasPreviousId": hasPreviousId,
      "currentPage": currentPage,
      "nextId": nextId,
      "hasNextId": hasNextId
    }
  else:
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": 0,
      "hasNextId": false
    }


proc fastPaginateBack*(self:Rdb, display, id:int, key="id", order:Order=Asc):Future[JsonNode]{.async.} =
  if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
  self.sqlString = @[self.selectBuilder().sqlString][0]
  let lastItem = await self.getLastItem(key, order)

  let where = if self.sqlString.contains("WHERE"): "AND" else: "WHERE"
  if order == Asc:
    self.sqlString = &"""
SELECT * FROM (
  {self.sqlString} {where} {key} > {id} ORDER BY {key} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {self.sqlString} {where} {key} <= {id} ORDER BY {key} DESC LIMIT {display+1}
) x
"""
  else:
    self.sqlString = &"""
SELECT * FROM (
  {self.sqlString} {where} {key} < {id} ORDER BY {key} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {self.sqlString} {where} {key} >= {id} ORDER BY {key} ASC LIMIT {display+1}
) x
"""
  self.placeHolder &= self.placeHolder
  logger(self.sqlString, self.placeHolder)
  var currentPage = await self.db.getAllRows(self.sqlString, self.placeHolder)
  if currentPage.len > 0:
    let newKey = if key.contains("."): key.split(".")[1] else: key
    # next
    let nextId = currentPage[0][newKey].getInt()
    var hasNextId = true
    if nextId != lastItem:
      currentPage.delete(0)
    else:
      hasNextId = false
    # previous
    let previousId = currentPage[currentPage.len-1][newKey].getInt
    var hasPreviousId = true
    if currentPage.len > display:
      discard currentPage.pop()
    else:
      hasPreviousId = false

    currentPage.reverse()

    return %*{
      "previousId": previousId,
      "hasPreviousId": hasPreviousId,
      "currentPage": currentPage,
      "nextId": nextId,
      "hasNextId": hasNextId
    }
  else:
    return %*{
      "previousId": 0,
      "hasPreviousId": false,
      "currentPage": currentPage,
      "nextId": 0,
      "hasNextId": false
    }
