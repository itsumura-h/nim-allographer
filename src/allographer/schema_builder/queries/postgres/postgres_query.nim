import ../../../query_builder/rdb/rdb_types
import ../query_interface


type PostgresQuery* = ref object
  rdb:Rdb

proc new*(_:type PostgresQuery, rdb:Rdb):PostgresQuery =
  return PostgresQuery(rdb:rdb)


proc toInterface*(self:PostgresQuery):IGenerator =
  return ()
  # return (
  #   resetTable:proc(table:Table) = self.resetTable(table),
  #   getHistories:proc(table:Table):JsonNode = self.getHistories(table),
  #   runQuery:proc(query:seq[string]) = self.runQuery(query),
  #   runQueryThenSaveHistory:proc(tableName:string, query:seq[string], checksum:string) = self.runQueryThenSaveHistory(tableName, query, checksum),
  #   createTableSql:proc(table:Table) = self.createTableSql(table),
  #   addColumnSql:proc(column:Column, table:Table) = self.addColumnSql(column, table),
  #   addColumn:proc(column:Column, table:Table) = self.addColumn(column, table),
  #   changeColumnSql:proc(column:Column, table:Table) = self.changeColumnSql(column, table),
  #   changeColumn:proc(column:Column, table:Table) = self.changeColumn(column, table),
  #   renameColumnSql:proc(column:Column, table:Table) = self.renameColumnSql(column, table),
  #   renameColumn:proc(column:Column, table:Table) = self.renameColumn(column, table),
  #   deleteColumnSql:proc(column:Column, table:Table) = self.deleteColumnSql(column, table),
  #   deleteColumn:proc(column:Column, table:Table) = self.deleteColumn(column, table),
  #   renameTableSql:proc(table:Table) = self.renameTableSql(table),
  #   renameTable:proc(table:Table) = self.renameTable(table),
  #   dropTableSql:proc(table:Table) = self.dropTableSql(table),
  #   dropTable:proc(table:Table) = self.dropTable(table),
  # )
