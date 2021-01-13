import json, strutils, strformat, algorithm, options, asyncdispatch
import base, builders
import ../utils
import ../connection


proc selectSql*(this: RDB):string =
  result = this.selectBuilder().sqlString & $this.placeHolder
  echo result

proc getColumns(db_columns:DbColumns):seq[array[3, string]] =
  var columns = newSeq[array[3, string]](db_columns.len)
  const DRIVER = getDriver()
  for i, row in db_columns:
    case DRIVER:
    of "sqlite":
      columns[i] = [row.name, row.typ.name, $row.typ.size]
    of "mysql":
      columns[i] = [row.name, $row.typ.kind, $row.typ.size]
    of "postgres":
      columns[i] = [row.name, $row.typ.kind, $row.typ.size]
  return columns

proc toJson(results:openArray[seq[string]], columns:openArray[array[3, string]]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  const DRIVER = getDriver()
  for index, rows in results.pairs:
    var response_row = newJObject()
    for i, row in rows:
      let key = columns[i][0]
      let typ = columns[i][1]
      let size = columns[i][2]

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

proc getAllRows(sqlString:string, args:seq[string]):seq[JsonNode] =
  let db = db()
  defer: db.close()

  var db_columns: DbColumns
  var rows = newSeq[seq[string]]()
  for row in db.instantRows(db_columns, sql sqlString, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)

  if rows.len == 0:
    echoErrorMsg(sqlString & $args)
    return newSeq[JsonNode](0)

  let columns = getColumns(db_columns)
  return toJson(rows, columns) # seq[JsonNode]

proc getAllRows(db:DbConn, sqlString:string, args:seq[string]):seq[JsonNode] =
  ## used in transaction
  var db_columns: DbColumns
  var rows = newSeq[seq[string]]()
  for row in db.instantRows(db_columns, sql sqlString, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)

  if rows.len == 0:
    echoErrorMsg(sqlString & $args)
    return newSeq[JsonNode](0)

  let columns = getColumns(db_columns)
  return toJson(rows, columns) # seq[JsonNode]

proc getAllRowsPlain*(sqlString:string, args:varargs[string]):seq[seq[string]] =
  let db = db()
  defer: db.close()
  return db.getAllRows(sql sqlString, args)

proc getAllRowsPlain*(db:DbConn, sqlString:string, args:varargs[string]):seq[seq[string]] =
  return db.getAllRows(sql sqlString, args)

proc getRow(sqlString:string, args:varargs[string]):JsonNode =
  let db = db()
  defer: db.close()

  var db_columns: DbColumns
  var rows = newSeq[seq[string]]()
  for row in db.instantRows(db_columns, sql sqlString, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)
    break

  if rows.len == 0:
    echoErrorMsg(sqlString & $args)
    return newJNull()

  let columns = getColumns(db_columns)
  return toJson(rows, columns)[0]

proc getRow(db:DbConn, sqlString:string, args:varargs[string]): JsonNode =
  ## used in transaction
  var db_columns: DbColumns
  var rows = newSeq[seq[string]]()
  for row in db.instantRows(db_columns, sql sqlString, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)
    break

  if rows.len == 0:
    echoErrorMsg(sqlString & $args)
    return newJNull()

  let columns = getColumns(db_columns)
  return toJson(rows, columns)[0]

proc getRowPlain(sqlString:string, args:varargs[string]):seq[string] =
  let db = db()
  defer: db.close()
  return db.getRow(sql sqlString, args)

proc getRowPlain(db:DbConn, sqlString:string, args:varargs[string]):seq[string] =
  return db.getRow(sql sqlString, args)

proc orm(rows:openArray[JsonNode], typ:typedesc):seq[typ.type] =
  var response = newSeq[typ.type](rows.len)
  for i, row in rows:
    response[i] = row.to(typ.type)
  return response

proc orm(row:JsonNode, typ:typedesc):typ.type =
  return row.to(typ)

# ==================== async pg ====================
when getDriver() == "postgres":
  proc asyncGet*(this: RDB): Future[seq[JsonNode]] {.async.} =
    defer: this.cleanUp()
    this.sqlString = this.selectBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      result = await asyncGetAllRows(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newSeq[JsonNode](0)

  proc asyncGetPlain*(this:RDB):Future[seq[Row]] {.async.}=
    defer: this.cleanUp()
    this.sqlString = this.selectBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetAllRowsPlain(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newSeq[Row]()

  proc asyncGetRow*(this:RDB):Future[JsonNode] {.async.}=
    defer: this.cleanUp()
    this.sqlString = this.selectBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetRow(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newJNull()

  proc asyncGetRowPlain*(this:RDB):Future[Row] {.async.}=
    defer: this.cleanUp()
    this.sqlString = this.selectBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetRowPlain(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newSeq[string](0)

  proc asyncFirst*(this: RDB): Future[JsonNode] {.async.} =
    defer: this.cleanUp()
    this.sqlString = this.selectFirstBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetRow(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newJNull()

  proc asyncFirstPlain*(this: RDB): Future[Row] {.async.} =
    defer: this.cleanUp()
    this.sqlString = this.selectFirstBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetRowPlain(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newSeq[string](0)

  proc asyncFind*(this: RDB, id: int, key="id"): Future[JsonNode] {.async.} =
    defer: this.cleanUp()
    this.placeHolder.add($id)
    this.sqlString = this.selectFindBuilder(id, key).sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetRow(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newJNull()

  proc asyncFindPlain*(this: RDB, id: int, key="id"): Future[Row] {.async.} =
    defer: this.cleanUp()
    this.placeHolder.add($id)
    this.sqlString = this.selectFindBuilder(id, key).sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      return await asyncGetRowPlain(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()
      return newSeq[string](0)

  proc asyncInsert*(this: RDB, items: JsonNode) {.async.} =
    defer: this.cleanUp()
    this.sqlString = this.insertValueBuilder(items).sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      await asyncExec(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()

  proc asyncInsert*(this: RDB, rows: seq[JsonNode]) {.async.} =
    defer: this.cleanUp()
    this.sqlString = this.insertValuesBuilder(rows).sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      await asyncExec(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()

  proc asyncInserts*(this: RDB, rows: seq[JsonNode]) {.async.} =
    defer: this.cleanUp()
    for row in rows:
      let sqlString = this.insertValueBuilder(row).sqlString
      logger(sqlString, this.placeHolder)
      try:
        await asyncExec(this.pool, sqlString, this.placeHolder)
        this.placeHolder = @[]
      except Exception:
        echoErrorMsg(sqlString & $this.placeHolder)
        getCurrentExceptionMsg().echoErrorMsg()
        break

  proc asyncUpdate*(this: RDB, items: JsonNode) {.async.} =
    defer: this.cleanUp()
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
    this.sqlString = this.updateBuilder(items).sqlString

    try:
      logger(this.sqlString, this.placeHolder)
      await asyncExec(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()

  proc asyncDelete*(this: RDB) {.async.} =
    defer: this.cleanUp()
    this.sqlString = this.deleteBuilder().sqlString
    try:
      logger(this.sqlString, this.placeHolder)
      await asyncExec(this.pool, this.sqlString, this.placeHolder)
    except Exception:
      echoErrorMsg(this.sqlString & $this.placeHolder)
      getCurrentExceptionMsg().echoErrorMsg()

# =============================================================================

proc toSql*(this: RDB): string =
  this.sqlString = this.selectBuilder().sqlString
  return this.sqlString

proc get*(this: RDB):seq[JsonNode] =
  defer: this.cleanUp()
  this.sqlString = this.selectBuilder().sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      result = getAllRows(this.sqlString, this.placeHolder)
    else:
      result = getAllRows(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc get*(this: RDB, typ: typedesc): seq[typ.type] =
  defer: this.cleanUp()
  this.sqlString = this.selectBuilder().sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getAllRows(this.sqlString, this.placeHolder).orm(typ)
    else:
      return getAllRows(this.db, this.sqlString, this.placeHolder).orm(typ)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[typ.type](0)

proc getPlain*(this:RDB):seq[seq[string]] =
  defer: this.cleanUp()
  this.sqlString = this.selectBuilder().sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getAllRowsPlain(this.sqlString, this.placeHolder)
    else:
      return getAllRowsPlain(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[seq[string]](0)

proc getRaw*(this: RDB): seq[JsonNode] =
  defer: this.cleanUp()
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getAllRows(this.sqlString, this.placeHolder)
    else:
      return getAllRows(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[JsonNode](0)

proc getRaw*(this: RDB, typ: typedesc): seq[typ.type] =
  defer: this.cleanUp()
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getAllRows(this.sqlString, this.placeHolder).orm(typ)
    else:
      return getAllRows(this.db, this.sqlString, this.placeHolder).orm(typ)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[typ.type](0)

proc first*(this: RDB): JsonNode =
  defer: this.cleanUp()
  this.sqlString = this.selectFirstBuilder().sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getRow(this.sqlString, this.placeHolder)
    else:
      return getRow(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newJNull()

proc first*(this: RDB, typ: typedesc):Option[typ.type] =
  defer: this.cleanUp()
  this.sqlString = this.selectFirstBuilder().sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getRow(this.sqlString, this.placeHolder).orm(typ).some()
    else:
      return getRow(this.db, this.sqlString, this.placeHolder).orm(typ).some()
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(typ.type)

proc firstPlain*(this: RDB): seq[string] =
  defer: this.cleanUp()
  this.sqlString = this.selectFirstBuilder().sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getRowPlain(this.sqlString, this.placeHolder)
    else:
      return getRowPlain(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[string](0)

proc find*(this: RDB, id: int, key="id"): JsonNode =
  defer: this.cleanUp()
  this.placeHolder.add($id)
  this.sqlString = this.selectFindBuilder(id, key).sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getRow(this.sqlString, this.placeHolder)
    else:
      return getRow(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newJNull()

proc find*(this: RDB, id: int, typ:typedesc, key="id"):Option[typ.type] =
  defer: this.cleanUp()
  this.placeHolder.add($id)
  this.sqlString = this.selectFindBuilder(id, key).sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getRow(this.sqlString, this.placeHolder).orm(typ).some()
    else:
      return getRow(this.db, this.sqlString, this.placeHolder).orm(typ).some()
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return none(typ.type)

proc findPlain*(this:RDB, id:int, key="id"):seq[string] =
  defer: this.cleanUp()
  this.placeHolder.add($id)
  this.sqlString = this.selectFindBuilder(id, key).sqlString
  try:
    logger(this.sqlString, this.placeHolder)
    if this.db.isNil:
      return getRowPlain(this.sqlString, this.placeHolder)
    else:
      return getRowPlain(this.db, this.sqlString, this.placeHolder)
  except Exception:
    echoErrorMsg(this.sqlString & $this.placeHolder)
    getCurrentExceptionMsg().echoErrorMsg()
    return newSeq[string](0)


# ==================== INSERT ====================

proc insertSql*(this: RDB, items: JsonNode):string =
  result = this.insertValueBuilder(items).sqlString & $this.placeHolder
  echo result

proc insert*(this: RDB, items: JsonNode) =
  defer: this.cleanUp()
  this.sqlString = this.insertValueBuilder(items).sqlString
  if this.db.isNil:
    logger(this.sqlString, this.placeHolder)
    let db = db()
    defer: db.close()
    db.exec(sql this.sqlString, this.placeHolder)
  else:
    logger(this.sqlString, this.placeHolder)
    this.db.exec(sql this.sqlString, this.placeHolder)

proc insert*(this: RDB, rows: openArray[JsonNode]) =
  defer: this.cleanUp()
  this.sqlString = this.insertValuesBuilder(rows).sqlString
  if this.db.isNil:
    logger(this.sqlString, this.placeHolder)
    let db = db()
    defer: db.close()
    db.exec(sql this.sqlString, this.placeHolder)
  else:
    logger(this.sqlString, this.placeHolder)
    this.db.exec(sql this.sqlString, this.placeHolder)

proc inserts*(this: RDB, rows: openArray[JsonNode]) =
  defer: this.cleanUp()
  if this.db.isNil:
    let db = db()
    defer: db.close()
    for row in rows:
      let sqlString = this.insertValueBuilder(row).sqlString
      logger(sqlString, this.placeHolder)
      db.exec(sql sqlString, this.placeHolder)
      this.placeHolder = @[]
  else:
     # in Transaction
    for row in rows:
      let sqlString = this.insertValueBuilder(row).sqlString
      logger(sqlString, this.placeHolder)
      this.db.exec(sql sqlString, this.placeHolder)
      this.placeHolder = @[]

proc insertID*(this: RDB, items: JsonNode):int =
  defer: this.cleanUp()
  this.sqlString = this.insertValueBuilder(items).sqlString
  if this.db.isNil:
    let db = db()
    defer: db.close()
    logger(this.sqlString, this.placeHolder)
    result = db.tryInsertID(sql this.sqlString, this.placeHolder).int()
  else:
    # in Transaction
    logger(this.sqlString, this.placeHolder)
    result = this.db.tryInsertID(sql this.sqlString, this.placeHolder).int()

proc insertID*(this: RDB, rows: openArray[JsonNode]):int =
  defer: this.cleanUp()
  this.sqlString = this.insertValuesBuilder(rows).sqlString
  var response: int
  if this.db.isNil:
    logger(this.sqlString, this.placeHolder)
    let db = db()
    defer: db.close()
    response = db.tryInsertID(sql this.sqlString, this.placeHolder).int()
    this.placeHolder = @[]
  else:
    logger(this.sqlString, this.placeHolder)
    response = this.db.tryInsertID(sql this.sqlString, this.placeHolder).int()
    this.placeHolder = @[]
  return response

proc insertsID*(this: RDB, rows: openArray[JsonNode]):seq[int] =
  defer: this.cleanUp()
  var response = newSeq[int](rows.len)
  if this.db.isNil:
    let db = db()
    defer: db.close()
    for i, row in rows:
      let sqlString = this.insertValueBuilder(row).sqlString
      logger(sqlString, this.placeHolder)
      response[i] = db.tryInsertID(sql sqlString, this.placeHolder).int()
      this.placeHolder = @[]
  else:
    for i, row in rows:
      let sqlString = this.insertValueBuilder(row).sqlString
      logger(sqlString, this.placeHolder)
      response[i] = this.db.tryInsertID(sql sqlString, this.placeHolder).int()
      this.placeHolder = @[]
  return response

# ==================== UPDATE ====================

proc updateSql*(this: RDB, items: JsonNode):string =
  defer: this.cleanUp()
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

  let placeHolder = updatePlaceHolder & this.placeHolder
  let sqlString = this.updateBuilder(items).sqlString

  result = sqlString & $placeHolder
  echo result

proc update*(this: RDB, items: JsonNode) =
  defer: this.cleanUp()
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

  this.placeHolder = updatePlaceHolder & this.placeHolder
  this.sqlString = this.updateBuilder(items).sqlString

  if this.db.isNil:
    logger(this.sqlString, this.placeHolder)
    let db = db()
    defer: db.close()
    db.exec(sql this.sqlString, this.placeHolder)
  else:
    logger(this.sqlString, this.placeHolder)
    this.db.exec(sql this.sqlString, this.placeHolder)


# ==================== DELETE ====================

proc deleteSql*(this: Rdb):string =
  result = this.deleteBuilder().sqlString & $this.placeHolder
  echo result

proc delete*(this: RDB) =
  defer: this.cleanUp()
  this.sqlString = this.deleteBuilder().sqlString
  if this.db.isNil:
    logger(this.sqlString, this.placeHolder)
    let db = db()
    defer: db.close()
    db.exec(sql this.sqlString, this.placeHolder)
  else:
    logger(this.sqlString, this.placeHolder)
    this.db.exec(sql this.sqlString, this.placeHolder)

proc delete*(this: RDB, id: int, key="id") =
  defer: this.cleanUp()
  this.placeHolder.add($id)
  this.sqlString = this.deleteByIdBuilder(id, key).sqlString
  if this.db.isNil:
    logger(this.sqlString, this.placeHolder)
    let db = db()
    defer: db.close()
    db.exec(sql this.sqlString, this.placeHolder)
  else:
    # in Transaction
    logger(this.sqlString, this.placeHolder)
    this.db.exec(sql this.sqlString, this.placeHolder)


# ==================== EXEC ====================

proc exec*(this: RDB) =
  ## It is only used with raw()
  defer: this.cleanUp()
  if this.db.isNil:
    let db = db()
    defer: db.close()
    logger(this.sqlString, this.placeHolder)
    db.exec(sql this.sqlString, this.placeHolder)
  else:
    logger(this.sqlString, this.placeHolder)
    this.db.exec(sql this.sqlString, this.placeHolder)


# ==================== Aggregates ====================

proc count*(this:RDB): int =
  this.sqlString = this.countBuilder().sqlString
  logger(this.sqlString, this.placeHolder)
  var response =  getRow(this.sqlString, this.placeHolder)
  let DRIVER = getDriver()
  case DRIVER
  of "sqlite":
    return response["aggregate"].getStr().parseInt()
  of "mysql":
    return response["aggregate"].getInt()
  of "postgres":
    return response["aggregate"].getInt()

proc max*(this:RDB, column:string): string =
  this.sqlString = this.maxBuilder(column).sqlString
  logger(this.sqlString, this.placeHolder)
  var response =  getRow(this.sqlString, this.placeHolder)
  case response["aggregate"].kind
  of JInt:
    return $(response["aggregate"].getInt())
  of JFloat:
    return $(response["aggregate"].getFloat())
  else:
    return response["aggregate"].getStr()

proc min*(this:RDB, column:string): string =
  this.sqlString = this.minBuilder(column).sqlString
  logger(this.sqlString, this.placeHolder)
  var response =  getRow(this.sqlString, this.placeHolder)
  case response["aggregate"].kind
  of JInt:
    return $(response["aggregate"].getInt())
  of JFloat:
    return $(response["aggregate"].getFloat())
  else:
    return response["aggregate"].getStr()

proc avg*(this:RDB, column:string): float =
  this.sqlString = this.avgBuilder(column).sqlString
  logger(this.sqlString, this.placeHolder)
  var response =  getRow(this.sqlString, this.placeHolder)
  let DRIVER = getDriver()
  case DRIVER
  of "sqlite":
    return response["aggregate"].getStr().parseFloat()
  else:
    return response["aggregate"].getFloat()

proc sum*(this:RDB, column:string): float =
  this.sqlString = this.sumBuilder(column).sqlString
  logger(this.sqlString, this.placeHolder)
  var response =  getRow(this.sqlString, this.placeHolder)
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


proc fastPaginate*(this:RDB, display:int, key="id", order:Order=Asc):JsonNode =
  this.sqlString = @[this.selectBuilder().sqlString][0]
  if order == Asc:
    this.sqlString = &"{this.sqlString} ORDER BY {key} ASC LIMIT {display + 1}"
  else:
    this.sqlString = &"{this.sqlString} ORDER BY {key} DESC LIMIT {display + 1}"
  logger(this.sqlString, this.placeHolder)
  var currentPage = getAllRows(this.sqlString, this.placeHolder)
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
      order:Order=Asc):JsonNode =
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
      order:Order=Asc):JsonNode =
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
