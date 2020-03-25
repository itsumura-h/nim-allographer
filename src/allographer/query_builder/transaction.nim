import macros, strutils, strformat
import ../connection, base


macro transaction*(bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr.replace("RDB()", "RDB(db:db)")
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(2)
  bodyStr = fmt"""
let db = query_builder.db()
# defer: db.close()
db.exec(sql"BEGIN")
try:
{bodyStr}
  db.exec(sql"COMMIT")
except:
  echo "=== rollback"
  db.exec(sql"ROLLBACK")
finally:
  echo "=== finished"
  echo db.repr
  db.close()
"""
  echo bodyStr
  let body = bodyStr.parseStmt()
  return body
