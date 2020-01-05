import db_sqlite, db_mysql, db_postgres
import json, strutils, strformat, algorithm

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
      else:
        response_row[key] = newJString(row)
  return response_row


proc getAllRows(sqlString:string, args:varargs[string]): seq[JsonNode] =
  let db = db()
  let results = db.getAllRows(sql sqlString, args) # seq[seq[string]]

  var db_columns: DbColumns
  block:
    for row in db.instantRows(db_columns, sql sqlString, args):
      discard
    defer: db.close()
    

  let columns = getColumns(db_columns)
  return toJson(results, columns) # seq[JsonNode]


proc getRow(sqlString:string, args:varargs[string]): JsonNode =
  let db = db()
  # TODO fix when Nim is upgraded https://github.com/nim-lang/Nim/pull/12806
  # let results = db.getRow(sql sqlString, args)
  let r = db.getAllRows(sql sqlString, args)
  var results = @[""]
  if r.len > 0:
    results = r[0]
  
  var db_columns: DbColumns
  block:
    for row in db.instantRows(db_columns, sql sqlString, args):
      discard
    defer: db.close()

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


proc get*(this: RDB): seq[JsonNode] =
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getAllRows(this.sqlStringSeq[0], this.placeHolder)

proc get*(this: RDB, typ: typedesc): seq[typ.type] =
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  logger(this.sqlStringSeq[0])
  return getAllRows(this.sqlStringSeq[0]).orm(typ)


proc getRaw*(this: RDB): seq[JsonNode] =
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getAllRows(this.sqlStringSeq[0], this.placeHolder)

proc getRaw*(this: RDB, typ: typedesc): seq[typ.type] =
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getAllRows(this.sqlStringSeq[0], this.placeHolder).orm(typ)


proc first*(this: RDB): JsonNode =
  this.sqlStringSeq = @[this.selectFirstBuilder().sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getRow(this.sqlStringSeq[0], this.placeHolder)

proc first*(this: RDB, typ: typedesc): typ.type =
  this.sqlStringSeq = @[this.selectFirstBuilder().sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getRow(this.sqlStringSeq[0], this.placeHolder).orm(typ)


proc find*(this: RDB, id: int, key="id"): JsonNode =
  this.placeHolder.add($id)
  this.sqlStringSeq = @[this.selectFindBuilder(id, key).sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getRow(this.sqlStringSeq[0], this.placeHolder)

proc find*(this: RDB, id: int, typ:typedesc, key="id"): typ.type =
  this.placeHolder.add($id)
  this.sqlStringSeq = @[this.selectFindBuilder(id, key).sqlString]
  logger(this.sqlStringSeq[0], this.placeHolder)
  return getRow(this.sqlStringSeq[0], this.placeHolder).orm(typ)


# ==================== INSERT ====================

proc insert*(this: RDB, items: JsonNode) =
  this.sqlStringSeq = @[this.insertValueBuilder(items).sqlString]
  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()

proc insert*(this: RDB, rows: openArray[JsonNode]) =
  this.sqlStringSeq = @[this.insertValuesBuilder(rows).sqlString]
  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()

proc inserts*(this: RDB, rows: openArray[JsonNode]) =
  this.sqlStringSeq = newSeq[string](rows.len)
  block:
    let db = db()
    for i, items in rows:
      var sqlString = this.insertValueBuilder(items).sqlString
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()


proc insertID*(this: RDB, items: JsonNode):int =
  this.sqlStringSeq = @[this.insertValueBuilder(items).sqlString]
  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      result = db.tryInsertID(sql sqlString, this.placeHolder).int()
    defer: db.close()

proc insertID*(this: RDB, rows: openArray[JsonNode]):seq[int] =
  this.sqlStringSeq = @[this.insertValuesBuilder(rows).sqlString]
  var response = newSeq[int](rows.len)
  block:
    let db = db()
    for i, sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      response[i] = db.tryInsertID(sql sqlString, this.placeHolder).int()
    defer: db.close()
  return response

proc insertsID*(this: RDB, rows: openArray[JsonNode]):seq[int] =
  this.sqlStringSeq = newSeq[string](rows.len)
  var response = newSeq[int](rows.len)
  block:
    let db = db()
    for i, items in rows:
      let sqlString = this.insertValueBuilder(items).sqlString
      logger(sqlString, this.placeHolder)
      response[i] = db.tryInsertID(sql sqlString, this.placeHolder).int()
      this.placeHolder = @[]
    defer: db.close()
  return response


# ==================== UPDATE ====================

proc update*(this: RDB, items: JsonNode) =
  var updatePlaceHolder: seq[string]
  for item in items.pairs:
    if item.val.kind == JInt:
      updatePlaceHolder.add($(item.val.getInt()))
    elif item.val.kind == JFloat:
      updatePlaceHolder.add($(item.val.getFloat()))
    else:
      updatePlaceHolder.add(item.val.getStr())

  this.placeHolder = updatePlaceHolder & this.placeHolder
  this.sqlStringSeq = @[this.updateBuilder(items).sqlString]

  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()


# ==================== DELETE ====================

proc delete*(this: RDB) =
  this.sqlStringSeq = @[this.deleteBuilder().sqlString]
  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()

proc delete*(this: RDB, id: int, key="id") =
  this.placeHolder.add($id)
  this.sqlStringSeq = @[this.deleteByIdBuilder(id, key).sqlString]
  block:
    let db = db()
    for sqlString in this.sqlStringSeq:
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
    defer: db.close()


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
  if not page > 0: raise newException(Exception, "arg2 should be larger than 0")
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


proc fastPaginate*(this:RDB, display:int, key="id"): JsonNode =
  this.sqlString = @[this.selectBuilder().sqlString][0]
  this.sqlString = &"{this.sqlString} LIMIT {display + 1}"
  logger(this.sqlString, this.placeHolder)
  var currentPage  = getAllRows(this.sqlString, this.placeHolder)
  let nextPage = currentPage.pop()[key].getInt()
  return %*{
    "previousPage": 0,
    "currentPage": currentPage,
    "nextPage": nextPage
  }


proc fastPaginateNext*(this:RDB, display:int, id:int=1, key="id"): JsonNode =
  this.sqlString = @[this.selectBuilder().sqlString][0]
  if this.query.hasKey("order_by"):
    var sqlStringSeq = this.sqlString.split("ORDER")
    echo sqlStringSeq
    this.sqlString = &"""
SELECT * FROM (
  {sqlStringSeq[0]} WHERE {key} > {id} ORDER{sqlStringSeq[1]} LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {sqlStringSeq[0]} WHERE {key} <= {id} ORDER{sqlStringSeq[1]} LIMIT {display}+1
) x
"""
  else:
    this.sqlString = &"""
SELECT * FROM (
  {this.sqlString} WHERE {key} < {id} ORDER BY {key} DESC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {this.sqlString} WHERE {key} >= {id} ORDER BY {key} ASC LIMIT {display}+1
) x
""" 
  logger(this.sqlString, this.placeHolder)
  var currentPage = getAllRows(this.sqlString, this.placeHolder)
  let previousPage = currentPage[0][key].getInt()
  currentPage.delete(0)
  let nextPage = currentPage.pop()[key].getInt()
  return %*{
    "previousPage": previousPage,
    "currentPage": currentPage,
    "nextPage": nextPage
  }


proc fastPaginateBack*(this:RDB, display:int, id:int=1, key="id"): JsonNode =
  this.sqlString = @[this.selectBuilder().sqlString][0]
  this.sqlString = &"""
SELECT * FROM (
  {this.sqlString} WHERE {key} > {id} ORDER BY {key} ASC LIMIT 1
) x
UNION ALL
SELECT * FROM (
  {this.sqlString} WHERE {key} <= {id} ORDER BY {key} DESC LIMIT {display}+1
) x
"""
  logger(this.sqlString, this.placeHolder)
  var currentPage  = getAllRows(this.sqlString, this.placeHolder)
  # next
  let nextPage = if currentPage[0][key].getInt() > id: currentPage[0][key].getInt() else: 0
  currentPage.delete(0)
  # previous
  var previousPage: int
  if currentPage.len() > display:
    previousPage = currentPage[display][key].getInt()
    discard currentPage.pop()
  else:
    previousPage = 0
  currentPage.reverse()
  return %*{
    "previousPage": previousPage,
    "currentPage": currentPage,
    "nextPage": nextPage
  }

# ==================== Transaction ====================

template transaction(body: untyped) =
  # TODO fix
  # echo treeRepr NimNode(body)
  block :
    let db = db()
    db.exec(sql"BEGIN")
    try:
      for s in body:
        for query in s.sqlStringSeq:
          db.exec(sql query)
      db.exec(sql"COMMIT")
      db.exec(sql"ROLLBACK")
    except:
      db.exec(sql"ROLLBACK")
      getCurrentExceptionMsg().echoErrorMsg()
    defer: db.close()
