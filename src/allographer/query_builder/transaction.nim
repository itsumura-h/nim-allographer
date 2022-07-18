import macros, strutils, strformat, asyncdispatch


macro transaction*(rdb:untyped, bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(4)
  bodyStr = fmt"""
block:
  let connI = {rdb.repr}.begin().await
  try:
{bodyStr}
    {rdb.repr}.commit(connI).await
  except:
    {rdb.repr}.rollback(connI).await
"""
  let body = bodyStr.parseStmt()
  return body
