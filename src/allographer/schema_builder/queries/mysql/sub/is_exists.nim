import std/asyncdispatch
import std/json
import std/options
import std/strformat
import ../../../models/table
import ../../../models/column
import ../../../../query_builder


proc isExistsIndex*(rdb:MysqlConnections, table:Table, column:Column):Future[bool] {.async.} =
  let res = rdb.raw(&"""
      SELECT count(*) as count
      FROM `INFORMATION_SCHEMA`.`STATISTICS`
      WHERE `TABLE_SCHEMA` = '{rdb.info.database}'
      AND `TABLE_NAME` = '{table.name}'
      AND `INDEX_NAME` = '{table.name}_{column.name}_index'
    """)
    .first()
    .waitFor()
  return res.isSome and res.get()["count"].getInt() > 0

proc isExistsUnique*(rdb:MysqlConnections, table:Table, column:Column):Future[bool] {.async.} =
  let res = rdb.raw(&"""
      SELECT count(*) as count
      FROM `INFORMATION_SCHEMA`.`STATISTICS`
      WHERE `TABLE_SCHEMA` = '{rdb.info.database}'
      AND `TABLE_NAME` = '{table.name}'
      AND `INDEX_NAME` = '{column.name}'
    """)
    .first()
    .waitFor()
  return res.isSome and res.get()["count"].getInt() > 0
