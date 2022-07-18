import json
import ../grammars

type IGenerator* = tuple
  resetTable:proc(table:Table)
  getHistories:proc(table:Table):JsonNode
  runQuery:proc(query:seq[string])
  runQueryThenSaveHistory:proc(tableName:string, query:seq[string], checksum:string)
  createTableSql:proc(table:Table)
  addColumnSql:proc(column:Column, table:Table)
  addColumn:proc(column:Column, table:Table)
  changeColumnSql:proc(column:Column, table:Table)
  changeColumn:proc(column:Column, table:Table)
  renameColumnSql:proc(column:Column, table:Table)
  renameColumn:proc(column:Column, table:Table)
  deleteColumnSql:proc(column:Column, table:Table)
  deleteColumn:proc(column:Column, table:Table)
  renameTableSql:proc(table:Table)
  renameTable:proc(table:Table)
  dropTableSql:proc(table:Table)
  dropTable:proc(table:Table)
