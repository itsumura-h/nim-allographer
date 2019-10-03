import db_sqlite, db_mysql, db_postgres
import json, parsecfg

import base, builders, logger


proc checkSql*(this: RDB): RDB =
  return this.selectBuilder()


proc get*(this: RDB, db: proc): seq =
  let sqlString = this.selectBuilder().sqlString
  logger(sqlString)
  let db = db()
  result = db.getAllRows(sql sqlString)
  defer: db.close()


proc first*(this: RDB, db: proc): seq =
  let sqlString = this.selectBuilder().sqlString
  logger(sqlString)
  let db = db()
  result = db.getRow(sql sqlString)
  defer: db.close()


proc find*(this: RDB, id: int, db: proc): seq =
  let sqlString = this.selectFindBuilder(id).sqlString
  logger(sqlString)
  let db = db()
  result = db.getRow(sql sqlString)
  defer: db.close()


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

proc exec*(this: RDB, db: proc) =
  let db = db()
  for sqlString in this.sqlStringSeq:
    logger(sqlString)
    db.exec(sql sqlString)

  defer: db.close()

