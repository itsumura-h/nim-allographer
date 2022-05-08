import macros, strutils, asyncdispatch
import ../base


template seeder*(rdb:Rdb, tableName:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  
  if rdb.table(tableName).count().waitFor == 0:
    body

template seeder*(rdb:Rdb, tableName, column:string, body:untyped):untyped =
  ## The `seeder` block allows the code in the block to work only when the table or specified column is empty.
  
  if rdb.table(tableName).select(column).count().waitFor == 0:
    body
