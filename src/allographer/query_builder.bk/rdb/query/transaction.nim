import std/macros
import std/strutils
import std/strformat
import ../rdb_types


macro rdbTransaction(rdb:Rdb, callback: untyped):untyped =
  var callbackStr = callback.repr
  callbackStr.removePrefix
  callbackStr = callbackStr.indent(4)
  callbackStr = fmt"""
block:
  let connI = {rdb.repr}.begin().await
  {rdb.repr}.inTransaction(connI)
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

template transaction*(rdb:Rdb, callback: untyped) =
  rdbTransaction(rdb, callback)
