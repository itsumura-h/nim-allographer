import base
import db_sqlite, db_mysql, db_postgres, json
import strformat

proc get*(this: DBObject): seq =
    let table = this.query["table"].getStr()
    var sqlString = &"SELECT * FROM {table}"
    return this.connection().getAllRows(sql sqlString)
  