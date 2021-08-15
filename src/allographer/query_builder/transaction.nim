import macros, strutils, strformat


macro transaction*(rdb:untyped, bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(4)
  bodyStr = fmt"""
block:
  try:
    await {rdb.repr}.raw("BEGIN").exec()
{bodyStr}
    await {rdb.repr}.raw("COMMIT").exec()
  except:
    await {rdb.repr}.raw("ROLLBACK").exec()
"""
  let body = bodyStr.parseStmt()
  return body
