import std/asyncdispatch
import std/strformat
import std/strutils
import std/sha1
import std/json
import std/times
import ../../../query_builder/enums as query_builder_enums
import ../../../query_builder/rdb/rdb_types
import ../../../query_builder/rdb/rdb_interface
import ../../../query_builder/rdb/query/grammar
import ../../enums as schema_builder_enums
import ../../models/table
import ../../models/column
import ../query_interface
import ./query_generator


type MysqlQuery* = ref object
  rdb:Rdb

proc new*(_:type MysqlQuery, rdb:Rdb):MysqlQuery =
  return MysqlQuery(rdb:rdb)


# ==================== private ====================
proc generateColumnString(column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.query = column.serialGenerator()
  of rdbInteger:
    column.query = column.intGenerator()
  of rdbSmallInteger:
    column.query = column.intGenerator()
  of rdbMediumInteger:
    column.query = column.intGenerator()
  of rdbBigInteger:
    column.query = column.intGenerator()
    # float
  of rdbDecimal:
    column.query = column.decimalGenerator()
  of rdbDouble:
    column.query = column.decimalGenerator()
  of rdbFloat:
    column.query = column.floatGenerator()
    # char
  of rdbUuid:
    column.query = column.stringGenerator()
  of rdbChar:
    column.query = column.charGenerator()
  of rdbString:
    column.query = column.stringGenerator()
    # text
  of rdbText:
    column.query = column.textGenerator()
  of rdbMediumText:
    column.query = column.textGenerator()
  of rdbLongText:
    column.query = column.textGenerator()
    # date
  of rdbDate:
    column.query = column.dateGenerator()
  of rdbDatetime:
    column.query = column.datetimeGenerator()
  of rdbTime:
    column.query = column.timeGenerator()
  of rdbTimestamp:
    column.query = column.timestampGenerator()
  of rdbTimestamps:
    column.query = column.timestampsGenerator()
  of rdbSoftDelete:
    column.query = column.softDeleteGenerator()
    # others
  of rdbBinary:
    column.query = column.blobGenerator()
  of rdbBoolean:
    column.query = column.boolGenerator()
  of rdbEnumField:
    column.query = column.enumGenerator()
  of rdbJson:
    column.query = column.jsonGenerator()
  # foreign
  of rdbForeign:
    column.query = column.foreignColumnGenerator()
  of rdbStrForeign:
    column.query = column.strForeignColumnGenerator()


proc generateForeignString(column:Column) =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.foreignQuery = column.foreignGenerator()


proc generateIndexString(table:Table, column:Column) =
  if column.isIndex and column.typ != rdbIncrements:
    column.indexQuery = column.indexGenerator(table)


# ==================== public ====================

proc resetMigrationTable(self:MysqlQuery, table:Table) =
  self.rdb.table("_migrations").where("name", "=", table.name).delete.waitFor


proc resetTable(self:MysqlQuery, table:Table) =
  self.rdb.raw(&"DROP TABLE IF EXISTS `{table.name}` CASCADE").exec.waitFor


proc getHistories(self:MysqlQuery, table:Table):JsonNode =
  let tables = self.rdb.table("_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table


proc exec*(self:MysqlQuery, table:Table) =
  for row in table.query:
    self.rdb.raw(row).exec.waitFor


proc execThenSaveHistory(self:MysqlQuery, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      self.rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()
  
  let tableQuery = queries.join("; ")
  self.rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": tableQuery,
    "checksum": checksum,
    "created_at": now().format("yyyy-MM-dd HH:mm:ss"),
    "status": isSuccess
  })
  .waitFor


# ==================== create table ====================

proc createTableSql(self:MysqlQuery, table:Table) =
  for i, column in table.columns:
    generateColumnString(column)
    generateForeignString(column)
    generateIndexString(table, column)

  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]
  for i, column in table.columns:
    if query.len > 0: query.add(", ")
    query.add(column.query)

    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(column.foreignQuery)
    
    if column.isIndex:
      indexQuery.add(column.indexQuery)

  if foreignQuery.len > 0:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS `{table.name}` ({query}, {foreignQuery})"
    )
  else:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS `{table.name}` ({query})"
    )

  table.query.add(indexQuery)
  table.checksum = $table.query.join("; ").secureHash()


# ==================== add Column ====================

proc addColumnSql(self:MysqlQuery, table:Table, column:Column) =
  generateColumnString(column)

  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    generateForeignString(column)
    column.queries.add(&"ALTER TABLE `{table.name}` ADD {column.foreignQuery}")
  else:
    column.queries.add(&"ALTER TABLE `{table.name}` ADD COLUMN {column.query}")
  
  if not column.isUnique and column.isIndex:
    generateIndexString(table, column)
    column.queries.add(column.indexQuery)

  column.checksum = $column.queries.join("; ").secureHash()


proc addColumn(self:MysqlQuery, table:Table, column:Column) =
  self.execThenSaveHistory(table.name, column.queries, column.checksum)


# ==================== change column ====================

proc changeColumnSql(self:MysqlQuery, table:Table, column:Column) =
  discard


proc changeColumn(self:MysqlQuery, table:Table, column:Column) =
  discard


proc toInterface*(self:MysqlQuery):IGenerator =
  return (
    resetMigrationTable:proc(table:Table) = self.resetMigrationTable(table),
    resetTable:proc(table:Table) = self.resetTable(table),
    getHistories:proc(table:Table):JsonNode = self.getHistories(table),
    exec:proc(table:Table) = self.exec(table),
    execThenSaveHistory:proc(tableName:string, queries:seq[string], checksum:string) = self.execThenSaveHistory(tableName, queries, checksum),
    createTableSql:proc(table:Table) = self.createTableSql(table),
    addColumnSql:proc(table:Table, column:Column) = self.addColumnSql(table, column),
    addColumn:proc(table:Table, column:Column) = self.addColumn(table, column),
    changeColumnSql:proc(table:Table, column:Column) = self.changeColumnSql(table, column),
    changeColumn:proc(table:Table, column:Column) = self.changeColumn(table, column),
  #   renameColumnSql:proc(column:Column, table:Table) = self.renameColumnSql(column, table),
  #   renameColumn:proc(column:Column, table:Table) = self.renameColumn(column, table),
  #   deleteColumnSql:proc(column:Column, table:Table) = self.deleteColumnSql(column, table),
  #   deleteColumn:proc(column:Column, table:Table) = self.deleteColumn(column, table),
  #   renameTableSql:proc(table:Table) = self.renameTableSql(table),
  #   renameTable:proc(table:Table) = self.renameTable(table),
  #   dropTableSql:proc(table:Table) = self.dropTableSql(table),
  #   dropTable:proc(table:Table) = self.dropTable(table),
  )
