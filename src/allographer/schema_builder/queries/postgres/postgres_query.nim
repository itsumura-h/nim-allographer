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


type PostgresQuery* = ref object
  rdb:Rdb

proc new*(_:type PostgresQuery, rdb:Rdb):PostgresQuery =
  return PostgresQuery(rdb:rdb)


# ==================== private ====================
proc generateColumnString(table:Table, column:Column, isAlter=false) =
  case column.typ:
    # int
  of rdbIncrements:
    column.query = column.serialGenerator(table, isAlter)
  of rdbInteger:
    column.query = column.intGenerator(table, isAlter)
  of rdbSmallInteger:
    column.query = column.intGenerator(table, isAlter)
  of rdbMediumInteger:
    column.query = column.intGenerator(table, isAlter)
  of rdbBigInteger:
    column.query = column.intGenerator(table, isAlter)
    # float
  of rdbDecimal:
    column.query = column.decimalGenerator(table, isAlter)
  of rdbDouble:
    column.query = column.decimalGenerator(table)
  of rdbFloat:
    column.query = column.floatGenerator(table, isAlter)
    # char
  of rdbUuid:
    column.query = column.stringGenerator(table, isAlter)
  of rdbChar:
    column.query = column.charGenerator(table, isAlter)
  of rdbString:
    column.query = column.stringGenerator(table, isAlter)
    # text
  of rdbText:
    column.query = column.textGenerator(table, isAlter)
  of rdbMediumText:
    column.query = column.textGenerator(table, isAlter)
  of rdbLongText:
    column.query = column.textGenerator(table, isAlter)
    # date
  of rdbDate:
    column.query = column.dateGenerator(table, isAlter)
  of rdbDatetime:
    column.query = column.datetimeGenerator(table, isAlter)
  of rdbTime:
    column.query = column.timeGenerator(table, isAlter)
  of rdbTimestamp:
    column.query = column.timestampGenerator(table, isAlter)
  of rdbTimestamps:
    column.query = column.timestampsGenerator(table)
  of rdbSoftDelete:
    column.query = column.softDeleteGenerator(table, isAlter)
    # others
  of rdbBinary:
    column.query = column.blobGenerator(table, isAlter)
  of rdbBoolean:
    column.query = column.boolGenerator(table, isAlter)
  of rdbEnumField:
    column.query = column.enumGenerator(table, isAlter)
  of rdbJson:
    column.query = column.jsonGenerator(table, isAlter)
  # foreign
  of rdbForeign:
    column.query = column.foreignColumnGenerator(table, isAlter)
  of rdbStrForeign:
    column.query = column.strForeignColumnGenerator(table, isAlter)


proc generateForeignString(table:Table, column:Column) =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.foreignQuery = column.foreignGenerator(table)


proc generateIndexString(table:Table, column:Column) =
  if column.isIndex:
    column.indexQuery = column.indexGenerater(table)


# ==================== public ====================

proc resetMigrationTable(self:PostgresQuery, table:Table) =
  self.rdb.table("_migrations").where("name", "=", table.name).delete.waitFor


proc resetTable(self:PostgresQuery, table:Table) =
  self.rdb.raw("DROP TABLE IF EXISTS \"?\"", [table.name]).exec.waitFor


proc getHistories(self:PostgresQuery, table:Table):JsonNode =
  let tables = self.rdb.table("_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table


proc createTableSql(self:PostgresQuery, table:Table) =
  for i, column in table.columns:
    generateColumnString(table, column)
    generateForeignString(table, column)
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
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query}, {foreignQuery})"
    )
  else:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query})"
    )

  table.query.add(indexQuery)
  table.checksum = $table.query.join("; ").secureHash()


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


proc toInterface*(self:PostgresQuery):IGenerator =
  return (
    resetMigrationTable:proc(table:Table) = self.resetMigrationTable(table),
    resetTable:proc(table:Table) = self.resetTable(table),
    getHistories:proc(table:Table):JsonNode = self.getHistories(table),
    exec:proc(table:Table) = self.exec(table),
    execThenSaveHistory:proc(tableName:string, queries:seq[string], checksum:string) = self.execThenSaveHistory(tableName, queries, checksum),
    createTableSql:proc(table:Table) = self.createTableSql(table),
    # addColumnSql:proc(column:Column, table:Table) = self.addColumnSql(table, column,),
    # addColumn:proc(column:Column, table:Table) = self.addColumn(table, column,),
    # changeColumnSql:proc(column:Column, table:Table) = self.changeColumnSql(table, column,),
    # changeColumn:proc(column:Column, table:Table) = self.changeColumn(table, column,),
    # renameColumnSql:proc(column:Column, table:Table) = self.renameColumnSql(table, column,),
    # renameColumn:proc(column:Column, table:Table) = self.renameColumn(table, column,),
    # deleteColumnSql:proc(column:Column, table:Table) = self.deleteColumnSql(table, column,),
    # deleteColumn:proc(column:Column, table:Table) = self.deleteColumn(table, column,),
    # renameTableSql:proc(table:Table) = self.renameTableSql(table),
    # renameTable:proc(table:Table) = self.renameTable(table),
    # dropTableSql:proc(table:Table) = self.dropTableSql(table),
    # dropTable:proc(table:Table) = self.dropTable(table),
  )
