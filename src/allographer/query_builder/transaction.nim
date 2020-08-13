import macros, strutils, strformat
import ../connection, base


macro transaction*(bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr.replace("RDB()", "RDB(db:db)")
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(4)
  bodyStr = fmt"""
block:
  # let db = db()
  # defer: db.close()
  try:
    rdb().db.exec(sql"BEGIN")
{bodyStr}
    rdb().db.exec(sql"COMMIT")
  except:
    echo getCurrentExceptionMsg()
    rdb().db.exec(sql"ROLLBACK")
"""
  let body = bodyStr.parseStmt()
  return body
