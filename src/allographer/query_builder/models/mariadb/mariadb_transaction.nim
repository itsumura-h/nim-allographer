import std/macros
import std/strutils
import std/strformat
import ../../models/mariadb/mariadb_types


macro rdbTransaction(rdb:MariadbConnections, callback: untyped):untyped =
  var callbackStr = callback.repr
  callbackStr.removePrefix
  callbackStr = callbackStr.indent(4)
  callbackStr = fmt"""
block:
  {rdb.repr}.begin().await
  try:
{callbackStr}
    {rdb.repr}.commit().await
  except:
    {rdb.repr}.rollback().await
"""
  let body = callbackStr.parseStmt()
  return body

template transaction*(rdb:MariadbConnections, callback: untyped) =
  rdbTransaction(rdb, callback)
