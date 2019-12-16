import db_sqlite, db_mysql, db_postgres
# import json, parsecfg, strutils
import json, strutils, times

import base, builders
import ../util
import ../connection


proc checkSql*(this: RDB): string =
  return this.selectBuilder().sqlString

proc getColumns(db_columns:DbColumns):seq[JsonNode] =
  var columns = newSeq[JsonNode](db_columns.len)
  const DRIVER = getDriver()
  for i, row in db_columns:
    # echo row
    case DRIVER:
    of "sqlite":
      columns[i] = %*{"name": row.name, "typ": row.typ.name}
    of "mysql":
      columns[i] = %*{"name": row.name, "typ": row.typ.kind}
    of "postgres":
      columns[i] = %*{"name": row.name, "typ": row.typ.kind}
  return columns

proc toJson(results:seq[seq[string]], columns:seq[JsonNode]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  const DRIVER = getDriver()
  for index, rows in results.pairs:
    var response_row = %*{}
    for i, row in rows:
      var key = columns[i]["name"].getStr
      var typ = columns[i]["typ"].getStr
      if DRIVER == "sqlite":
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
      else:
        if row == "":
          response_row[key] = newJNull()
        elif [$dbInt, $dbUInt].contains(typ):
          response_row[key] = newJInt(row.parseInt)
        elif [$dbDecimal, $dbFloat].contains(typ):
          response_row[key] = newJFloat(row.parseFloat)
        elif [$dbBool].contains(typ):
          response_row[key] = newJBool(row.parseBool)
        else:
          response_row[key] = newJString(row)

    response_table[index] = response_row
  return response_table

proc toJson(results:seq[string], columns:seq[JsonNode]):JsonNode =
  var response_row = %*{}
  const DRIVER = getDriver()
  for i, row in results:
    var key = columns[i]["name"].getStr
    var typ = columns[i]["typ"].getStr
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
      elif [$dbInt, $dbUInt].contains(typ):
        response_row[key] = newJInt(row.parseInt)
      elif [$dbDecimal, $dbFloat].contains(typ):
        response_row[key] = newJFloat(row.parseFloat)
      elif [$dbBool].contains(typ):
        response_row[key] = newJBool(row.parseBool)
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
        response_row[key] = newJBool(row.parseBool)
      else:
        response_row[key] = newJString(row)
    # var key = columns[i]["name"].getStr
    # response_row[key] = newJString(row)
  return response_row


proc getAllRows(sqlString:string): seq[JsonNode] =
  let db = db()
  let results = db.getAllRows(sql sqlString) # seq[seq[string]]

  var db_columns: DbColumns
  for row in db.instantRows(db_columns, sql sqlString):
    discard
  defer: db.close()

  let columns = getColumns(db_columns)
  return toJson(results, columns) # seq[JsonNode]


proc getRow(sqlString:string): JsonNode =
  let db = db()
  # let results = db.getRow(sql sqlString)
  let results = db.getAllRows(sql sqlString)[0]
  
  var db_columns: DbColumns
  for row in db.instantRows(db_columns, sql sqlString):
    discard
  defer: db.close()

  let columns = getColumns(db_columns)
  return toJson(results, columns)

proc orm[T](rows:seq[JsonNode], typ:T):seq[T] =
  var response: seq[T]
  for i, row in rows:
    response.add(row.to(T))
  return response

proc orm[T](row:JsonNode, typ:T):T =
  return row.to(T)

# =============================================================================

proc get*(this: RDB): seq[JsonNode] =
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  logger(this.sqlStringSeq[0])
  return getAllRows(this.sqlStringSeq[0])

proc get*[T](this: RDB, typ: T): seq[T] =
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  logger(this.sqlStringSeq[0])
  return getAllRows(this.sqlStringSeq[0]).orm(typ)


proc getRaw*(this: RDB): seq[JsonNode] =
  logger(this.sqlStringSeq[0])
  return getAllRows(this.sqlStringSeq[0])

proc getRaw*[T](this: RDB, typ: T): seq[T] =
  logger(this.sqlStringSeq[0])
  return getAllRows(this.sqlStringSeq[0]).orm(typ)


proc first*(this: RDB): JsonNode =
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  logger(this.sqlStringSeq[0])
  return getRow(this.sqlStringSeq[0])

proc first*[T](this: RDB, typ: T): T =
  this.sqlStringSeq = @[this.selectBuilder().sqlString]
  logger(this.sqlStringSeq[0])
  return getRow(this.sqlStringSeq[0]).orm(typ)


proc find*(this: RDB, id: int, key="id"): JsonNode =
  this.sqlStringSeq = @[this.selectFindBuilder(id, key).sqlString]
  logger(this.sqlStringSeq[0])
  return getRow(this.sqlStringSeq[0])

proc find*[T](this: RDB, id: int, typ:T, key="id"): T =
  this.sqlStringSeq = @[this.selectFindBuilder(id, key).sqlString]
  logger(this.sqlStringSeq[0])
  return getRow(this.sqlStringSeq[0]).orm(typ)


# ==================== INSERT ====================

proc insert*(this: RDB, items: JsonNode): RDB =
  this.sqlStringSeq = @[this.insertValueBuilder(items).sqlString]
  return this

proc insert*(this: RDB, rows: openArray[JsonNode]): RDB =
  this.sqlStringSeq = @[this.insertValuesBuilder(rows).sqlString]
  return this

proc inserts*(this: RDB, rows: openArray[JsonNode]): RDB =
  for items in rows:
    this.sqlStringSeq.add(
      this.insertValueBuilder(items).sqlString
    )
  return this


# ==================== UPDATE ====================

proc update*(this: RDB, items: JsonNode): RDB =
  this.sqlStringSeq.add(
    this.updateBuilder(items).sqlString
  )
  return this


# ==================== DELETE ====================

proc delete*(this: RDB): RDB =
  this.sqlStringSeq = @[this.deleteBuilder().sqlString]
  return this

proc delete*(this: RDB, id: int, key="id"): RDB =
  this.sqlStringSeq = @[this.deleteByIdBuilder(id, key).sqlString]
  return this


# ==================== EXEC ====================

proc exec*(this: RDB) =
  let db = db()
  for sqlString in this.sqlStringSeq:
    logger(sqlString)
    db.exec(sql sqlString)
  defer: db.close()

proc execID*(this: RDB): int64 =
  let db = db()

  # insert Multi
  if this.sqlStringSeq.len == 1 and this.sqlString.contains("INSERT"):
    logger(this.sqlString)
    result = db.tryInsertID(
      sql this.sqlStringSeq[0]
    )
  else:
    for sqlString in this.sqlStringSeq:
      logger(sqlString)
      db.exec(sql sqlString)
    result = 0

  defer: db.close()


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
