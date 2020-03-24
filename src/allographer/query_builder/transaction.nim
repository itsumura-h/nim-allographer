import macros, strutils, strformat
import ../connection, base

proc addDb(bobyStr:string):string =
  return bobyStr.replace("RDB()", "RDB(db:db)")

macro transaction*(bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr.addDb()
  var body = parseStmt(fmt"""
let db = db()
defer: db.close()
try:
  db.exec(sql"BEGIN")
  {bodyStr}
except:
  db.exec(sql"ROLLBACK")
db.exec(sql"COMMIT")
""")
  echo body
  return body
