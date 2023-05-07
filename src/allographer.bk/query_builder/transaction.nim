import std/macros
import std/strutils
import std/strformat


macro transaction*(rdb:untyped, bodyInput: untyped):untyped =
  var bodyStr = bodyInput.repr
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(4)
  bodyStr = fmt"""
block:
  let connI = {rdb.repr}.begin().await
  rdb.inTransaction(connI)
  try:
{bodyStr}
    {rdb.repr}.commit(connI).await
  except:
    {rdb.repr}.rollback(connI).await
  finally:
    {rdb.repr}.freeTransactionConn(connI)
"""
  let body = bodyStr.parseStmt()
  return body
