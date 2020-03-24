import macros, strutils, strformat
import ../connection, base


macro transaction*(bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr
                .replace("RDB()", "RDB(db:db)")
                .indent(2)
  bodyStr = fmt"""
let db = query_builder.db()
defer: db.close()
try:
  db.exec(sql"BEGIN")
{bodyStr}
  db.exec(sql"COMMIT")
except:
  db.exec(sql"ROLLBACK")
"""
  echo bodyStr
  let body = bodyStr.parseStmt()
  return body
