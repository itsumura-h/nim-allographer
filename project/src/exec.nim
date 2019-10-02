import db_sqlite, db_mysql, db_postgres
import json, os, strformat, strutils, parsecfg

import base, builders, generators


proc get*(this: RDB, db: proc): seq =
  let sqlString = this.select().sqlString
  let db = db()
  echo sqlString
  result = db.getAllRows(sql sqlString)
  defer: db.close()


proc first*(this: RDB, db: proc): seq =
  let sqlString = this.select().sqlString
  let db = db()
  echo sqlString
  result = db.getRow(sql sqlString)
  defer: db.close()


proc find*(thisArg: RDB, id: int, db: proc): seq =
  var this = thisArg.selectSql().fromSql()
  this.sqlString.add(&" WHERE id = {$id}")

  let db = db()
  echo this.sqlString
  result = db.getRow(sql this.sqlString)
  defer: db.close()


## ==================== INSERT ====================

proc insert*(this: RDB, items: JsonNode): RDB =
  this.sqlStringSeq.add(
    this
    .insertSql()
    .insertValueSql(items)
    .sqlString
  )
  return this

proc insert*(this: RDB, rows: openArray[JsonNode]): RDB =
  this.sqlStringSeq.add(
    this
    .insertSql()
    .insertValuesSql(rows)
    .sqlString
  )
  return this

proc insertDifferentColumns*(this: RDB, rows: openArray[JsonNode]): RDB =
  for items in rows:
    this.sqlStringSeq.add(
      this
      .insertSql()
      .insertValueSql(items)
      .sqlString
    )
  return this

proc exec*(this: RDB, db: proc) =
  let db = db()
  for sqlString in this.sqlStringSeq:
    echo sqlString
    db.exec(sql sqlString)

  defer: db.close()
