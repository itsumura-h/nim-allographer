import std/json
import ../models/column
import ../models/table


type IGenerator* = tuple
  resetMigrationTable:proc(table:Table)
  resetTable:proc(table:Table)
  getHistories:proc(table:Table):JsonNode
  exec:proc(table:Table)
  execThenSaveHistory:proc(table:Table)
  createTableSql:proc(table:Table)
  # addColumnSql:proc(column:Column, table:Table)
  # addColumn:proc(column:Column, table:Table)
  # changeColumnSql:proc(column:Column, table:Table)
  # changeColumn:proc(column:Column, table:Table)
  # renameColumnSql:proc(column:Column, table:Table)
  # renameColumn:proc(column:Column, table:Table)
  # deleteColumnSql:proc(column:Column, table:Table)
  # deleteColumn:proc(column:Column, table:Table)
  # renameTableSql:proc(table:Table)
  # renameTable:proc(table:Table)
  # dropTableSql:proc(table:Table)
  # dropTable:proc(table:Table)
