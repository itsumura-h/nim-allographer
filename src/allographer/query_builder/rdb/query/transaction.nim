import std/macros
import std/strutils
import std/strformat


macro transaction*(rdb:untyped, callback: untyped):untyped =
  var callbackStr = callback.repr
  callbackStr.removePrefix
  callbackStr = callbackStr.indent(4)
  callbackStr = fmt"""
block:
  let connI = {rdb.repr}.begin().await
  rdb.inTransaction(connI)
  try:
{callbackStr}
    {rdb.repr}.commit(connI).await
  except:
    {rdb.repr}.rollback(connI).await
  finally:
    {rdb.repr}.freeTransactionConn(connI)
"""
  let body = callbackStr.parseStmt()
  return body
