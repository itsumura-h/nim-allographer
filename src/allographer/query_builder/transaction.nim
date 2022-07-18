import macros, strutils, strformat


macro transaction*(rdb:untyped, bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(4)
  bodyStr = fmt"""
block:
  try:
    {rdb.repr}.raw("BEGIN").exec().await
{bodyStr}
    {rdb.repr}.raw("COMMIT").exec().await
  except:
    {rdb.repr}.raw("ROLLBACK").exec().await
"""
  let body = bodyStr.parseStmt()
  return body
