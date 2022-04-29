import json
import ../grammers

type IGenerator* = tuple
  resetTable:proc(table:Table)
  getHistories:proc(table:Table):JsonNode
  runQuery:proc(query:string)
  runQueryThenSaveHistory:proc(tableName, query, checksum:string)
  createTableSql:proc(table:Table)
  addColumnSql:proc(column:Column, table:Table)
  changeColumnSql:proc(column:Column)
  changeColumn:proc(column:Column, table:Table)
  renameColumnSql:proc(column:Column, table:Table)
  renameColumn:proc(column:Column, table:Table)
  deleteColumnSql:proc(column:Column, table:Table)
  deleteColumn:proc(column:Column, table:Table)
  renameTableSql:proc(table:Table)
  renameTable:proc(table:Table)
  dropTableSql:proc(table:Table)
  dropTable:proc(table:Table)
