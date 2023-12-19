import std/macros
import std/strutils
import std/strformat
import ../../models/postgres/postgres_types


macro rdbTransaction(rdb:PostgresQuery, callback: untyped):untyped =
  var callbackStr = callback.repr
  callbackStr.removePrefix
  callbackStr = callbackStr.indent(4)
  callbackStr = fmt"""
block:
  {rdb.repr}.begin().await
  try:
{callbackStr}
    {rdb.repr}.commit().await
  except DbError, CatchableError:
    {rdb.repr}.rollback().await
"""
  let body = callbackStr.parseStmt()
  return body

template transaction*(rdb:PostgresQuery, callback: untyped) =
  rdbTransaction(rdb, callback)
