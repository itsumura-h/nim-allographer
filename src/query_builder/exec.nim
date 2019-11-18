import db_sqlite, db_mysql, db_postgres
# import json, parsecfg, strutils
import json, strutils

import base, builders
import ../util
import ../connection


proc checkSql*(this: RDB): RDB =
  return this.selectBuilder()

proc getColumns(this:RDB, sqlString:string):seq[JsonNode] =
  var db_columns: DbColumns
  let db = db()
  for row in db.instantRows(db_columns, sql sqlString):
    discard
  defer: db.close()
  var columns: seq[JsonNode]
  for i, row in db_columns:
    columns.add(
      %*{
        "name": row.name,
        "typ": row.typ.name
      }
    )
  return columns

proc toJson(results:seq[string], columns:seq[JsonNode]):JsonNode =
  var response_row = %*{}
  for i, row in results:
    var key = columns[i]["name"].getStr
    var typ = columns[i]["typ"].getStr
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
    # var key = columns[i]["name"].getStr
    # response_row[key] = newJString(row)
  return response_row

proc toJson(results:seq[seq[string]], columns:seq[JsonNode]):seq[JsonNode] =
  var response_table: seq[JsonNode]
  for rows in results:
    var response_row = %*{}
    for i, row in rows:
      var key = columns[i]["name"].getStr
      var typ = columns[i]["typ"].getStr
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
      # var key = columns[i]["name"].getStr
      # response_row[key] = newJString(row)
    response_table.add(response_row)
  return response_table

# =============================================================================

proc get*(this: RDB): seq[JsonNode] =
  let sqlString = this.selectBuilder().sqlString
  logger(sqlString)
  let db = db()
  let results = db.getAllRows(sql sqlString) # seq[seq[string]]
  defer: db.close()
  let columns = getColumns(this, sqlString)
  return toJson(results, columns) # seq[JsonNode]

proc getRaw*(this: RDB): seq[JsonNode] =
  let sqlString = this.sqlString
  logger(sqlString)
  let db = db()
  let results = db.getAllRows(sql sqlString) # seq[seq[string]]
  defer: db.close()
  let columns = getColumns(this, sqlString)
  return toJson(results, columns) # seq[JsonNode]


proc first*(this: RDB): JsonNode =
  let sqlString = this.selectBuilder().sqlString
  logger(sqlString)
  let db = db()
  let results = db.getRow(sql sqlString)
  defer: db.close()
  let columns = getColumns(this, sqlString)
  return toJson(results, columns)


proc find*(this: RDB, id: int): JsonNode =
  let sqlString = this.selectFindBuilder(id).sqlString
  logger(sqlString)
  let db = db()
  let results = db.getRow(sql sqlString)
  defer: db.close()
  let columns = getColumns(this, sqlString)
  return toJson(results, columns)


## ==================== INSERT ====================

proc insert*(this: RDB, items: JsonNode): RDB =
  this.sqlStringSeq.add(
    this.insertValueBuilder(items).sqlString
  )
  return this

proc insert*(this: RDB, rows: openArray[JsonNode]): RDB =
  this.sqlStringSeq.add(
    this.insertValuesBuilder(rows).sqlString
  )
  return this

proc inserts*(this: RDB, rows: openArray[JsonNode]): RDB =
  for items in rows:
    this.sqlStringSeq.add(
      this.insertValueBuilder(items).sqlString
    )
  return this


## ==================== UPDATE ====================

proc update*(this: RDB, items: JsonNode): RDB =
  this.sqlStringSeq.add(
    this.updateBuilder(items).sqlString
  )
  return this


## ==================== DELETE ====================

proc delete*(this: RDB): RDB =
  this.sqlStringSeq.add(
    this.deleteBuilder().sqlString
  )
  return this

proc delete*(this: RDB, id: int): RDB =
  this.sqlStringSeq.add(
    this.deleteByIdBuilder(id).sqlString
  )
  return this


## ==================== EXEC ====================

proc exec*(this: RDB) =
  let db = db()
  for sqlString in this.sqlStringSeq:
    logger(sqlString)
    db.exec(sql sqlString)

  defer: db.close()

# proc execRaw*(this:RDB): seq[JsonNode] =
#   let db = db()
#   let results = db.exec(sql this.sqlStringSeq[0])
#   defer: db.close()
#   let columns = getColumns(this, this.sqlStringSeq[0])
#   return toJson(results, columns) # seq[JsonNode]

proc execID*(this: RDB): int64 =
  let db = db()

  # insert Multi
  if this.sqlStringSeq.len == 1 and this.sqlString.contains("INSERT"):
    logger(this.sqlString)
    result = db.tryInsertID(
      sql this.sqlString
    )
  else:
    for sqlString in this.sqlStringSeq:
      logger(sqlString)
      db.exec(sql sqlString)
    result = 0   

  defer: db.close()
