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
import ./change_column_generator


type PostgresQuery* = ref object
  rdb:Rdb

proc new*(_:type PostgresQuery, rdb:Rdb):PostgresQuery =
  return PostgresQuery(rdb:rdb)


# ==================== private ====================
proc generateColumnString(table:Table, column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.query = column.serialGenerator(table)
  of rdbInteger:
    column.query = column.intGenerator(table)
  of rdbSmallInteger:
    column.query = column.intGenerator(table)
  of rdbMediumInteger:
    column.query = column.intGenerator(table)
  of rdbBigInteger:
    column.query = column.intGenerator(table)
    # float
  of rdbDecimal:
    column.query = column.decimalGenerator(table)
  of rdbDouble:
    column.query = column.decimalGenerator(table)
  of rdbFloat:
    column.query = column.floatGenerator(table)
    # char
  of rdbUuid:
    column.query = column.stringGenerator(table)
  of rdbChar:
    column.query = column.charGenerator(table)
  of rdbString:
    column.query = column.stringGenerator(table)
    # text
  of rdbText:
    column.query = column.textGenerator(table)
  of rdbMediumText:
    column.query = column.textGenerator(table)
  of rdbLongText:
    column.query = column.textGenerator(table)
    # date
  of rdbDate:
    column.query = column.dateGenerator(table)
  of rdbDatetime:
    column.query = column.datetimeGenerator(table)
  of rdbTime:
    column.query = column.timeGenerator(table)
  of rdbTimestamp:
    column.query = column.timestampGenerator(table)
  of rdbTimestamps:
    column.query = column.timestampsGenerator(table)
  of rdbSoftDelete:
    column.query = column.softDeleteGenerator(table)
    # others
  of rdbBinary:
    column.query = column.blobGenerator(table)
  of rdbBoolean:
    column.query = column.boolGenerator(table)
  of rdbEnumField:
    column.query = column.enumGenerator(table)
  of rdbJson:
    column.query = column.jsonGenerator(table)
  # foreign
  of rdbForeign:
    column.query = column.foreignColumnGenerator(table)
  of rdbStrForeign:
    column.query = column.strForeignColumnGenerator(table)


proc generateForeignString(table:Table, column:Column) =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.foreignQuery = column.foreignGenerator(table)


proc generateIndexString(table:Table, column:Column) =
  if column.isIndex and column.typ != rdbIncrements:
    column.indexQuery = column.indexGenerator(table)


proc generateChangeColumnString(table:Table, column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.queries = column.serialChangeGenerator(table)
  of rdbInteger:
    column.queries = column.intChangeGenerator(table)
  of rdbSmallInteger:
    column.queries = column.smallIntChangeGenerator(table)
  of rdbMediumInteger:
    column.queries = column.mediumIntChangeGenerator(table)
  of rdbBigInteger:
    column.queries = column.bigIntChangeGenerator(table)
  # float
  of rdbDecimal:
    column.queries = column.decimalChangeGenerator(table)
  of rdbDouble:
    column.queries = column.decimalChangeGenerator(table)
  of rdbFloat:
    column.queries = column.floatChangeGenerator(table)
    # char
  of rdbChar:
    column.queries = column.charChangeGenerator(table)
  of rdbString:
    column.queries = column.stringChangeGenerator(table)
  of rdbUuid:
    column.queries = column.stringChangeGenerator(table)
    # text
  of rdbText:
    column.queries = column.textChangeGenerator(table)
  of rdbMediumText:
    column.queries = column.textChangeGenerator(table)
  of rdbLongText:
    column.queries = column.textChangeGenerator(table)
    # date
  of rdbDate:
    column.queries = column.dateChangeGenerator(table)
  of rdbDatetime:
    column.queries = column.datetimeChangeGenerator(table)
  of rdbTime:
    column.queries = column.timeChangeGenerator(table)
  of rdbTimestamp:
    column.queries = column.timestampChangeGenerator(table)
  # of rdbTimestamps:
  #   column.queries = column.timestampsChangeGenerator(table)
  # of rdbSoftDelete:
  #   column.queries = column.softDeleteChangeGenerator(table)
    # others
  of rdbBinary:
    column.queries = column.blobChangeGenerator(table)
  of rdbBoolean:
    column.queries = column.boolChangeGenerator(table)
  of rdbEnumField:
    column.queries = column.enumChangeGenerator(table)
  of rdbJson:
    column.queries = column.jsonChangeGenerator(table)
  # # foreign
  # of rdbForeign:
  #   column.queries = column.foreignColumnChangeGenerator(table, isAlter)
  # of rdbStrForeign:
  #   column.queries = column.strForeignColumnChangeGenerator(table, isAlter)
  else:
    discard


# ==================== public ====================

proc resetMigrationTable(self:PostgresQuery, table:Table) =
  self.rdb.table("_migrations").where("name", "=", table.name).delete.waitFor


proc resetTable(self:PostgresQuery, table:Table) =
  self.rdb.raw(&"DROP TABLE IF EXISTS \"{table.name}\"").exec.waitFor


proc getHistories(self:PostgresQuery, table:Table):JsonNode =
  let tables = self.rdb.table("_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table


proc exec*(self:PostgresQuery, table:Table) =
  for row in table.query:
    self.rdb.raw(row).exec.waitFor


proc execThenSaveHistory(self:PostgresQuery, tableName:string, queries:seq[string], checksum:string) =
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
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor


# ==================== create table ====================

proc createTableSql(self:PostgresQuery, table:Table) =
  for i, column in table.columns:
    generateColumnString(table, column)

  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]
  for i, column in table.columns:
    if query.len > 0: query.add(", ")
    query.add(column.query)

    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      generateForeignString(table, column)
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(column.foreignQuery)
    
    if not column.isUnique and column.isIndex:
      generateIndexString(table, column)
      indexQuery.add(column.indexQuery)

  if foreignQuery.len > 0:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query}, {foreignQuery})"
    )
  else:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query})"
    )

  table.query.add(indexQuery)
  table.checksum = $table.query.join("; ").secureHash()


# ==================== add Column ====================

proc addColumnSql(self:PostgresQuery, table:Table, column:Column) =
  generateColumnString(table, column)

  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    generateForeignString(table, column)
    column.queries.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN {column.query} {column.foreignQuery}")
  else:
    column.queries.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN {column.query}")
  
  if not column.isUnique and column.isIndex:
    generateIndexString(table, column)
    column.queries.add(column.indexQuery)

  column.checksum = $column.queries.join("; ").secureHash()


proc addColumn(self:PostgresQuery, table:Table, column:Column) =
  self.execThenSaveHistory(table.name, column.queries, column.checksum)


# ==================== change column ====================

proc changeColumnSql(self:PostgresQuery, table:Table, column:Column) =
  generateChangeColumnString(table, column)
  
  if not column.isUnique and column.isIndex:
    generateIndexString(table, column)
    column.queries.add(column.indexQuery)

  column.checksum = $column.queries.join("; ").secureHash()


proc changeColumn(self:PostgresQuery, table:Table, column:Column) =
  self.execThenSaveHistory(table.name, column.queries, column.checksum)


proc toInterface*(self:PostgresQuery):IGenerator =
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
    # renameColumnSql:proc(column:Column, table:Table) = self.renameColumnSql(table, column,),
    # renameColumn:proc(column:Column, table:Table) = self.renameColumn(table, column,),
    # deleteColumnSql:proc(column:Column, table:Table) = self.deleteColumnSql(table, column,),
    # deleteColumn:proc(column:Column, table:Table) = self.deleteColumn(table, column,),
    # renameTableSql:proc(table:Table) = self.renameTableSql(table),
    # renameTable:proc(table:Table) = self.renameTable(table),
    # dropTableSql:proc(table:Table) = self.dropTableSql(table),
    # dropTable:proc(table:Table) = self.dropTable(table),
  )
