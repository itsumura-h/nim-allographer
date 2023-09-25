import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import ../../src/allographer/query_builder

proc clearTables*(rdb:SurrealConnections) {.async.} =
  let dbInfo = rdb.raw("INFO FOR DB").info().await
  let tables = dbInfo[0]["result"]["tb"]
  for (table, _) in tables.pairs:
    if not table.startsWith("_"):
      rdb.raw(&"REMOVE TABLE {table}").exec().await
