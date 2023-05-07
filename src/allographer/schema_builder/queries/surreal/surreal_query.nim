import std/json
import std/options
import std/strformat
import std/asyncdispatch
import std/sha1
import std/times
import std/strutils
import ../../../types
import ../../../query_builder
import ../../grammars
import ../query_interface
import ./impl


type SurrealQuery* = ref object
  rdb:Rdb

proc new*(_:type SurrealQuery, rdb:Rdb):SurrealQuery =
  return SurrealQuery(rdb:rdb)


# ==================== public ====================
proc resetTable(self:SurrealQuery, table:Table) =
  discard

proc getHistories(self:SurrealQuery, table:Table):JsonNode =
  discard

proc runQuery(self:SurrealQuery, query:seq[string]) =
  discard

proc runQueryThenSaveHistory(self:SurrealQuery, tableName:string, query:seq[string], checksum:string) =
  discard

proc createTableSql(self:SurrealQuery, table:Table) =
  discard

proc addColumnSql(self:SurrealQuery, column:Column, table:Table) =
  discard

proc addColumn(self:SurrealQuery, column:Column, table:Table) =
  discard

proc changeColumnSql(self:SurrealQuery, column:Column, table:Table) =
  discard

proc changeColumn(self:SurrealQuery, column:Column, table:Table) =
  discard

proc renameColumnSql(self:SurrealQuery, column:Column, table:Table) =
  discard

proc renameColumn(self:SurrealQuery, column:Column, table:Table) =
  discard

proc deleteColumnSql(self:SurrealQuery, column:Column, table:Table) =
  discard

proc deleteColumn(self:SurrealQuery, column:Column, table:Table) =
  discard

proc renameTableSql*(self:SurrealQuery, table:Table) =
  discard

proc renameTable(self:SurrealQuery, table:Table) =
  discard

proc dropTableSql(self:SurrealQuery, table:Table) =
  discard

proc dropTable(self:SurrealQuery, table:Table) =
  discard

proc toInterface*(self:SurrealQuery):IGenerator =
  return (
    resetTable:proc(table:Table) = self.resetTable(table),
    getHistories:proc(table:Table):JsonNode = self.getHistories(table),
    runQuery:proc(query:seq[string]) = self.runQuery(query),
    runQueryThenSaveHistory:proc(tableName:string, query:seq[string], checksum:string) = self.runQueryThenSaveHistory(tableName, query, checksum),
    createTableSql:proc(table:Table) = self.createTableSql(table),
    addColumnSql:proc(column:Column, table:Table) = self.addColumnSql(column, table),
    addColumn:proc(column:Column, table:Table) = self.addColumn(column, table),
    changeColumnSql:proc(column:Column, table:Table) = self.changeColumnSql(column, table),
    changeColumn:proc(column:Column, table:Table) = self.changeColumn(column, table),
    renameColumnSql:proc(column:Column, table:Table) = self.renameColumnSql(column, table),
    renameColumn:proc(column:Column, table:Table) = self.renameColumn(column, table),
    deleteColumnSql:proc(column:Column, table:Table) = self.deleteColumnSql(column, table),
    deleteColumn:proc(column:Column, table:Table) = self.deleteColumn(column, table),
    renameTableSql:proc(table:Table) = self.renameTableSql(table),
    renameTable:proc(table:Table) = self.renameTable(table),
    dropTableSql:proc(table:Table) = self.dropTableSql(table),
    dropTable:proc(table:Table) = self.dropTable(table),
  )
