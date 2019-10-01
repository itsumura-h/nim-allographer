import db_sqlite, db_mysql, db_postgres
import base
import json, os, strformat, strutils, parsecfg

proc get*(this: RDB, conn: proc): seq =
  let table = this.query["table"].getStr()
  echo table
  let sqlString = &"SELECT * from {table}"
  result = conn().getAllRows(sql sqlString)
  echo result