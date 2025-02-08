import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import ../src/allographer/query_builder


proc clearTables*(rdb:PostgresConnections) {.async.} =
  try:
    let tables = rdb.table("_allographer_migrations").orderBy("id", Desc) .get().await
    for table in tables:
      let tableName = table["name"].getStr()
      if not tableName.startsWith("_"):
        rdb.raw(&"DROP TABLE IF EXISTS \"{tableName}\"").exec().await

    rdb.raw("DROP TABLE IF EXISTS \"_allographer_migrations\"").exec().await
  except:
    echo "error: ", getCurrentExceptionMsg()


proc clearTables*(rdb:MariaDBConnections) {.async.} =
  try:
    let tables = rdb.table("_allographer_migrations").orderBy("id", Desc) .get().await
    for table in tables:
      let tableName = table["name"].getStr()
      if not tableName.startsWith("_"):
        rdb.raw(&"DROP TABLE IF EXISTS `{tableName}`").exec().await
    
    rdb.raw("DROP TABLE IF EXISTS `_allographer_migrations`").exec().await
  except:
    echo "error: ", getCurrentExceptionMsg()


proc clearTables*(rdb:MySQLConnections) {.async.} =
  try:
    let tables = rdb.table("_allographer_migrations").orderBy("id", Desc) .get().await
    for table in tables:
      let tableName = table["name"].getStr()
      if not tableName.startsWith("_"):
        rdb.raw(&"DROP TABLE IF EXISTS `{tableName}`").exec().await
    
    rdb.raw("DROP TABLE IF EXISTS `_allographer_migrations`").exec().await
  except:
    echo "error: ", getCurrentExceptionMsg()


proc clearTables*(rdb:SqliteConnections) {.async.} =
  try:
    let tables = rdb.table("_allographer_migrations").orderBy("id", Desc) .get().await
    for table in tables:
      let tableName = table["name"].getStr()
      if not tableName.startsWith("_"):
        rdb.raw(&"DROP TABLE IF EXISTS \"{tableName}\"").exec().await

    rdb.raw("DROP TABLE IF EXISTS \"_allographer_migrations\"").exec().await
  except:
    echo "error: ", getCurrentExceptionMsg()


proc clearTables*(rdb:SurrealConnections) {.async.} =
  try:
    let dbInfo = rdb.raw("INFO FOR DB").info().await
    let tables = dbInfo[0]["result"]["tb"]
    for (table, _) in tables.pairs:
      if not table.startsWith("_"):
        rdb.raw(&"REMOVE TABLE {table}").exec().await
  
    rdb.raw(&"REMOVE TABLE _allographer_migrations").exec().await
    rdb.raw(&"REMOVE TABLE _autoincrement_sequences").exec().await
  except:
    echo "error: ", getCurrentExceptionMsg()
