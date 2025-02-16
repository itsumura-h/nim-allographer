import std/macros
import std/strutils
import std/strformat
import ../../models/postgres/postgres_types


when NimMajor == 1:
  macro rdbTransaction(rdb:PostgresConnections, callback: untyped):untyped =
    var callbackStr = callback.repr
    callbackStr.removePrefix
    callbackStr = callbackStr.indent(4)
    callbackStr = fmt"""
block:
  {rdb.repr}.begin().await
  try:
{callbackStr}
    {rdb.repr}.commit().await
  except DbError:
    {rdb.repr}.rollback().await
"""
    let body = callbackStr.parseStmt()
    return body
else:
  macro rdbTransaction(rdb:PostgresConnections, callback: untyped):untyped =
    var callbackStr = callback.repr
    callbackStr.removePrefix
    callbackStr = callbackStr.indent(4)
    callbackStr = fmt"""
block:
  {rdb.repr}.begin().await
  try:
{callbackStr}
    {rdb.repr}.commit().await
  except CatchableError:
    {rdb.repr}.rollback().await
"""
    let body = callbackStr.parseStmt()
    return body


template transaction*(rdb:PostgresConnections, callback: untyped) =
  rdbTransaction(rdb, callback)
