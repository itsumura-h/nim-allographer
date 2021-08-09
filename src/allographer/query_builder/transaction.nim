import macros, strutils, strformat


macro transaction*(bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr.replace("rdb()", "Rdb(db:db())")
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(4)
  bodyStr = fmt"""
block:
  let db = db()
  defer: db.close()
  try:
    db.exec(sql"BEGIN")
{bodyStr}
    db.exec(sql"COMMIT")
  except:
    echo getCurrentExceptionMsg()
    db.exec(sql"ROLLBACK")
"""
  let body = bodyStr.parseStmt()
  return body
