import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import ../../../src/allographer/query_builder

proc clearTables*(rdb:MariaDBConnections) {.async.} =
  let tables = rdb.table("_allographer_migrations").orderBy("id", Desc) .get().await
  for table in tables:
    let tableName = table["name"].getStr()
    if not tableName.startsWith("_"):
      rdb.raw(&"DROP TABLE IF EXISTS `{tableName}`").exec().await
  
  rdb.raw("DROP TABLE IF EXISTS `_allographer_migrations`").exec().await
