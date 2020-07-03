import json, strutils, strformat, algorithm, options

import base, builders
import ../util
import ../connection


proc checkSql*(this: RDB): string =
  return this.selectBuilder().sqlString

proc getColumns(db_columns:DbColumns):seq[JsonNode] =
  var columns = newSeq[JsonNode](db_columns.len)
  const DRIVER = getDriver()
  for i, row in db_columns:
    case DRIVER:
    of "sqlite":
      columns[i] = %*{"name": row.name, "typ": row.typ.name, "size": row.typ.size}
    of "mysql":
      columns[i] = %*{"name": row.name, "typ": row.typ.kind, "size": row.typ.size}
    of "postgres":
      columns[i] = %*{"name": row.name, "typ": row.typ.kind, "size": row.typ.size}
  return columns

proc toJson(results:openArray[seq[string]], columns:openArray[JsonNode]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  const DRIVER = getDriver()
  for index, rows in results.pairs:
    var response_row = %*{}
    for i, row in rows:
      let key = columns[i]["name"].getStr
      let typ = columns[i]["typ"].getStr
      let size = columns[i]["size"].getInt

      case DRIVER:
      of "sqlite":
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
      of "mysql":
        if row == "":
          response_row[key] = newJNull()
        elif [$dbInt, $dbUInt].contains(typ) and size == 1:
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
      of "postgres":
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

proc toJson(results:openArray[string], columns:openArray[JsonNode]):JsonNode =
  var response_row = %*{}
  const DRIVER = getDriver()
  for i, row in results:
    let key = columns[i]["name"].getStr
    let typ = columns[i]["typ"].getStr
    let size = columns[i]["size"].getInt

    case DRIVER:
    of "sqlite":
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
    of "mysql":
      if row == "":
        response_row[key] = newJNull()
      elif [$dbInt, $dbUInt].contains(typ) and size == 1:
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
    of "postgres":
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
  return response_row

proc getAllRows(sqlString:string, args:varargs[string]): seq[JsonNode] =
  let db = db()
  defer: db.close()
  let results = db.getAllRows(sql sqlString, args) # seq[seq[string]]
  if results.len == 0:
    echoErrorMsg(sqlString & $args)
    return newSeq[JsonNode](0)

  var db_columns: DbColumns
  for row in db.instantRows(db_columns, sql sqlString, args):
    discard

  let columns = getColumns(db_columns)
  return toJson(results, columns) # seq[JsonNode]

proc getAllRows(db:DbConn, sqlString:string, args:varargs[string]): seq[JsonNode] =
  ## used in transaction
  let results = db.getAllRows(sql sqlString, args) # seq[seq[string]]
  if results.len == 0:
    echoErrorMsg(sqlString & $args)
    return newSeq[JsonNode](0)

  var db_columns: DbColumns
  block:
    for row in db.instantRows(db_columns, sql sqlString, args):
      discard

  let columns = getColumns(db_columns)
  return toJson(results, columns) # seq[JsonNode]


proc getRow(sqlString:string, args:varargs[string]): JsonNode =
  let db = db()
  defer: db.close()
  # TODO fix when Nim is upgraded https://github.com/nim-lang/Nim/pull/12806
  # let results = db.getRow(sql sqlString, args)
  let r = db.getAllRows(sql sqlString, args)
  echo r
  var results: seq[string]
  if r.len > 0:
    results = r[0]
  else:
    echoErrorMsg(sqlString & $args)
    return newJNull()

  var db_columns: DbColumns
  for row in db.instantRows(db_columns, sql sqlString, args):
    discard

  let columns = getColumns(db_columns)
  return toJson(results, columns)

proc getRow(db:DbConn, sqlString:string, args:varargs[string]): JsonNode =
  # TODO fix when Nim is upgraded https://github.com/nim-lang/Nim/pull/12806
  # let results = db.getRow(sql sqlString, args)
  let r = db.getAllRows(sql sqlString, args)
  echo r
  var results: seq[string]
  if r.len > 0:
    results = r[0]
  else:
    echoErrorMsg(sqlString & $args)
    return newJNull()

  var db_columns: DbColumns
  block:
    for row in db.instantRows(db_columns, sql sqlString, args):
      discard

  let columns = getColumns(db_columns)
  return toJson(results, columns)

proc orm(rows:openArray[JsonNode], typ:typedesc):seq[typ.type] =
  var response = newSeq[typ.type](rows.len)
  for i, row in rows:
    response[i] = row.to(typ.type)
  return response

proc orm(row:JsonNode, typ:typedesc):typ.type =
  return row.to(typ)

# =============================================================================

proc toSql*(this: RDB): string =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  return this.sqlStringSeq[0]

proc get*(this: RDB): seq[JsonNode] =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    if not this.isInTransaction:
      return getAllRows(this.sqlStringSeq[0], this.placeHolder)
    else:
      # in Transaction
      return getAllRows(this.db, this.sqlStringSeq[0], this.placeHolder)
    # return getAllRows(this.sqlStringSeq[0], this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc get*(this: RDB, typ: typedesc): seq[typ.type] =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    return getAllRows(this.sqlStringSeq[0]).orm(typ)
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[typ.type](0)


proc getRaw*(this: RDB): seq[JsonNode] =
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    if not this.isInTransaction:
      return getAllRows(this.sqlStringSeq[0], this.placeHolder)
    else:
      # in Transaction
      return getAllRows(this.db, this.sqlStringSeq[0], this.placeHolder)
    # return getAllRows(this.sqlStringSeq[0], this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc getRaw*(this: RDB, typ: typedesc): seq[typ.type] =
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    return getAllRows(this.sqlStringSeq[0], this.placeHolder).orm(typ)
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[typ.type](0)

proc first*(this: RDB): JsonNode =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.sqlStringSeq = @[this.selectFirstBuilder().sqlString]
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    if not this.isInTransaction:
      return getRow(this.sqlStringSeq[0], this.placeHolder)
    else:
      # in Transaction
      return getRow(this.db, this.sqlStringSeq[0], this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newJNull()

proc first*(this: RDB, typ: typedesc): Option[typ.type] =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.sqlStringSeq = @[this.selectFirstBuilder().sqlString]
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    return getRow(this.sqlStringSeq[0], this.placeHolder).orm(typ).some()
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return typ.none()


proc find*(this: RDB, id: int, key="id"): JsonNode =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.placeHolder.add($id)
  this.sqlStringSeq = @[this.selectFindBuilder(id, key).sqlString]
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    if not this.isInTransaction:
      return getRow(this.sqlStringSeq[0], this.placeHolder)
    else:
      # in Transaction
      return getRow(this.db, this.sqlStringSeq[0], this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newJNull()

proc find*(this: RDB, id: int, typ:typedesc, key="id"): Option[typ.type] =
  defer:
    this.sqlString = "";
    this.placeHolder = newSeq[string](0);
    this.query = %*{"table": this.query["table"].getStr}
  this.placeHolder.add($id)
  this.sqlStringSeq = @[this.selectFindBuilder(id, key).sqlString]
  try:
    logger(this.sqlStringSeq[0], this.placeHolder)
    return getRow(this.sqlStringSeq[0], this.placeHolder).orm(typ).some()
  except Exception:
    echoErrorMsg(this.sqlStringSeq[0] & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return typ.none()


# ==================== INSERT ====================

proc insert*(this: RDB, items: JsonNode) =
  this.sqlStringSeq = @[this.insertValueBuilder(items).sqlString]
  if not this.isInTransaction:
    let db = db()
    defer:
      db.close()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
  else:
    # in Transaction
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)

proc insert*(this: RDB, rows: openArray[JsonNode]) =
  this.sqlStringSeq = @[this.insertValuesBuilder(rows).sqlString]
  if not this.isInTransaction:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    if getDriver() != "sqlite":
      defer: db.close()
  else:
    # in Transaction
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)

proc inserts*(this: RDB, rows: openArray[JsonNode]) =
  this.sqlStringSeq = newSeq[string](rows.len)
  if not this.isInTransaction:
    let db = db()
    defer: db.close()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
  else:
     # in Transaction
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)


proc insertID*(this: RDB, items: JsonNode):int =
  this.sqlStringSeq = @[this.insertValueBuilder(items).sqlString]
  if not this.isInTransaction:
    let db = db()
    defer: db.close()
    let sqlString = this.sqlStringSeq[0]
    logger(sqlString, this.placeHolder)
    result = db.tryInsertID(sql sqlString, this.placeHolder).int()
  else:
    # in Transaction
    let sqlString = this.sqlStringSeq[0]
    logger(sqlString, this.placeHolder)
    result = this.db.tryInsertID(sql sqlString, this.placeHolder).int()

proc insertID*(this: RDB, rows: openArray[JsonNode]):seq[int] =
  this.sqlStringSeq = @[this.insertValuesBuilder(rows).sqlString]
  var response = newSeq[int](rows.len)
  if not this.isInTransaction:
    let db = db()
    defer: db.close()
    for i, sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      response[i] = db.tryInsertID(sql sqlString, this.placeHolder).int()
  else:
    # in Transaction
    for i, sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      response[i] = this.db.tryInsertID(sql sqlString, this.placeHolder).int()
  return response

proc insertsID*(this: RDB, rows: openArray[JsonNode]):seq[int] =
  this.sqlStringSeq = newSeq[string](rows.len)
  var response = newSeq[int](rows.len)
  if not this.isInTransaction:
    let db = db()
    defer: db.close()
    for i, items in rows:
      let sqlString = this.insertValueBuilder(items).sqlString
      logger(sqlString, this.placeHolder)
      response[i] = db.tryInsertID(sql sqlString, this.placeHolder).int()
      this.placeHolder = @[]
  else:
    # in Transaction
    for i, items in rows:
      let sqlString = this.insertValueBuilder(items).sqlString
      logger(sqlString, this.placeHolder)
      response[i] = this.db.tryInsertID(sql sqlString, this.placeHolder).int()
      this.placeHolder = @[]
  return response

# ==================== UPDATE ====================

proc update*(this: RDB, items: JsonNode) =
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

  this.placeHolder = updatePlaceHolder & this.placeHolder
  this.sqlStringSeq = @[this.updateBuilder(items).sqlString]

  if not this.isInTransaction:
    let db = db()
    defer: db.close()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
  else:
    # in Transaction
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)


# ==================== DELETE ====================

proc delete*(this: RDB) =
  this.sqlStringSeq = @[this.deleteBuilder().sqlString]
  if not this.isInTransaction:
    let db = db()
    defer: db.close()
  else:
    # in Transaction
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)

proc delete*(this: RDB, id: int, key="id") =
  this.placeHolder.add($id)
  this.sqlStringSeq = @[this.deleteByIdBuilder(id, key).sqlString]
  if not this.isInTransaction:
    let db = db()
    defer: db.close()
  else:
    # in Transaction
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)


# ==================== EXEC ====================

proc exec*(this: RDB) =
  ## It is only used with raw()
  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()


# ==================== Aggregates ====================

proc count*(this:RDB): int =
  this.sqlStringSeq = @[this.countBuilder().sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  var response =  getRow(this.sqlStringSeq[0], this.placeHolder)
  let DRIVER = getDriver()
  case DRIVER
  of "sqlite":
    return response["aggregate"].getStr().parseInt()
  of "mysql":
    return response["aggregate"].getInt()
  of "postgres":
    return response["aggregate"].getInt()

proc max*(this:RDB, column:string): string =
  this.sqlStringSeq = @[this.maxBuilder(column).sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  var response =  getRow(this.sqlStringSeq[0], this.placeHolder)
  case response["aggregate"].kind
  of JInt:
    return $(response["aggregate"].getInt())
  of JFloat:
    return $(response["aggregate"].getFloat())
  else:
    return response["aggregate"].getStr()

proc min*(this:RDB, column:string): string =
  this.sqlStringSeq = @[this.minBuilder(column).sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  var response =  getRow(this.sqlStringSeq[0], this.placeHolder)
  case response["aggregate"].kind
  of JInt:
    return $(response["aggregate"].getInt())
  of JFloat:
    return $(response["aggregate"].getFloat())
  else:
    return response["aggregate"].getStr()

proc avg*(this:RDB, column:string): float =
  this.sqlStringSeq = @[this.avgBuilder(column).sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  var response =  getRow(this.sqlStringSeq[0], this.placeHolder)
  let DRIVER = getDriver()
  case DRIVER
  of "sqlite":
    return response["aggregate"].getStr().parseFloat()
  else:
    return response["aggregate"].getFloat()

proc sum*(this:RDB, column:string): float =
  this.sqlStringSeq = @[this.sumBuilder(column).sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  var response =  getRow(this.sqlStringSeq[0], this.placeHolder)
  let DRIVER = getDriver()
  case DRIVER
  of "sqlite":
    return response["aggregate"].getStr().parseFloat()
  else:
    return response["aggregate"].getFloat()


# ==================== Paginate ====================

from grammars import where, limit, offset, orderBy, Order

proc paginate*(this:RDB, display:int, page:int=1): JsonNode =
  if not page > 0: raise newException(Exception, "Arg page should be larger than 0")
  let total = this.count()
  let offset = (page - 1) * display
  let currentPage = this.limit(display).offset(offset).get()
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


proc getFirstItem(this:RDB, keyArg:string, order:Order=Asc):int =
  var sqlString = this.sqlString
  if order == Asc:
    sqlString = &"{sqlString} ORDER BY {keyArg} ASC LIMIT 1"
  else:
    sqlString = &"{sqlString} ORDER BY {keyArg} DESC LIMIT 1"
  let row = getRow(sqlString, this.placeHolder)
  let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
  return row[key].getInt


proc getLastItem(this:RDB, keyArg:string, order:Order=Asc):int =
  var sqlString = this.sqlString
  if order == Asc:
    sqlString = &"{sqlString} ORDER BY {keyArg} DESC LIMIT 1"
  else:
    sqlString = &"{sqlString} ORDER BY {keyArg} ASC LIMIT 1"
  let row = getRow(sqlString, this.placeHolder)
  let key = if keyArg.contains("."): keyArg.split(".")[1] else: keyArg
  return row[key].getInt


proc fastPaginate*(this:RDB, display:int, key="id", order:Order=Asc): JsonNode =
  this.sqlString = @[this.selectBuilder().sqlString][0]
  if order == Asc:
    this.sqlString = &"{this.sqlString} ORDER BY {key} ASC LIMIT {display + 1}"
  else:
    this.sqlString = &"{this.sqlString} ORDER BY {key} DESC LIMIT {display + 1}"
  logger(this.sqlString, this.placeHolder)
  var currentPage  = getAllRows(this.sqlString, this.placeHolder)
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


proc fastPaginateNext*(this:RDB, display:int, id:int, key="id",
                        order:Order=Asc): JsonNode =
  if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
  this.sqlString = @[this.selectBuilder().sqlString][0]
  let firstItem = getFirstItem(this, key, order)

  let where = if this.sqlString.contains("WHERE"): "AND" else: "WHERE"
  if order == Asc:
    this.sqlString = &"""
SELECT * FROM (
  {this.sqlString} {where} {key} < {id} ORDER BY {key} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {this.sqlString} {where} {key} >= {id} ORDER BY {key} ASC LIMIT {display+1}
) x
"""
  else:
    this.sqlString = &"""
SELECT * FROM (
  {this.sqlString} {where} {key} > {id} ORDER BY {key} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {this.sqlString} {where} {key} <= {id} ORDER BY {key} DESC LIMIT {display+1}
) x
"""
  this.placeHolder &= this.placeHolder
  logger(this.sqlString, this.placeHolder)
  var currentPage = getAllRows(this.sqlString, this.placeHolder)
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


proc fastPaginateBack*(this:RDB, display:int, id:int, key="id",
                        order:Order=Asc): JsonNode =
  if not id > 0: raise newException(Exception, "Arg id should be larger than 0")
  this.sqlString = @[this.selectBuilder().sqlString][0]
  let lastItem = getLastItem(this, key, order)

  let where = if this.sqlString.contains("WHERE"): "AND" else: "WHERE"
  if order == Asc:
    this.sqlString = &"""
SELECT * FROM (
  {this.sqlString} {where} {key} > {id} ORDER BY {key} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {this.sqlString} {where} {key} <= {id} ORDER BY {key} DESC LIMIT {display+1}
) x
"""
  else:
    this.sqlString = &"""
SELECT * FROM (
  {this.sqlString} {where} {key} < {id} ORDER BY {key} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {this.sqlString} {where} {key} >= {id} ORDER BY {key} ASC LIMIT {display+1}
) x
"""
  this.placeHolder &= this.placeHolder
  logger(this.sqlString, this.placeHolder)
  var currentPage = getAllRows(this.sqlString, this.placeHolder)
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
