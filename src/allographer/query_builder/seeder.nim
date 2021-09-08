import macros, strutils, asyncdispatch
import ../base


template seeder*(rdb:Rdb, tableName:string, body:untyped):untyped =
  if waitFor(rdb.table(tableName).count()) == 0:
    body

template seeder*(rdb:Rdb, tableName, column:string, body:untyped):untyped =
  if waitFor(rdb.table(tableName).select(column).count()) == 0:
    body
