import std/json
import ../models/column
import ../models/table


type IGenerator* = tuple
  # resetMigrationTable:proc(table:Table)
  # resetTable:proc(table:Table)
  # getHistories:proc(table:Table):JsonNode
  # shouldRunAddColumn:proc(column:Column, isReset:bool):bool
  # exec:proc(table:Table)
  # execThenSaveHistory:proc(tableName:string, query:seq[string], checksum:string)
  createTableSql:proc(table:Table)
  addColumnSql:proc(table:Table, column:Column)
  addColumn:proc(table:Table, column:Column)
  changeColumnSql:proc(table:Table, column:Column)
  changeColumn:proc(table:Table, column:Column)
  # renameColumnSql:proc(column:Column, table:Table)
  # renameColumn:proc(column:Column, table:Table)
  # deleteColumnSql:proc(column:Column, table:Table)
  # deleteColumn:proc(column:Column, table:Table)
  # renameTableSql:proc(table:Table)
  # renameTable:proc(table:Table)
  # dropTableSql:proc(table:Table)
  # dropTable:proc(table:Table)
