import std/json
import std/options
import std/strformat
import std/asyncdispatch
import std/sha1
import std/times
import std/strutils
import ../../../query_builder
import ../../grammars
import ../query_interface
import ./impl


type PostgreQuery* = ref object
  rdb:Rdb

proc new*(_:type PostgreQuery, rdb:Rdb):PostgreQuery =
  return PostgreQuery(rdb:rdb)

# ==================== private ====================
proc generateColumnString(column:Column, table:Table, isAlter=false):string =
  case column.typ:
    # int
  of rdbIncrements:
    return column.serialGenerator(table, isAlter)
  of rdbInteger:
    return column.intGenerator(table, isAlter)
  of rdbSmallInteger:
    return column.intGenerator(table, isAlter)
  of rdbMediumInteger:
    return column.intGenerator(table, isAlter)
  of rdbBigInteger:
    return column.intGenerator(table, isAlter)
    # float
  of rdbDecimal:
    return column.decimalGenerator(table, isAlter)
  of rdbDouble:
    return column.decimalGenerator(table)
  of rdbFloat:
    return column.floatGenerator(table, isAlter)
    # char
  of rdbUuid:
    return column.stringGenerator(table, isAlter)
  of rdbChar:
    return column.charGenerator(table, isAlter)
  of rdbString:
    return column.stringGenerator(table, isAlter)
    # text
  of rdbText:
    return column.textGenerator(table, isAlter)
  of rdbMediumText:
    return column.textGenerator(table, isAlter)
  of rdbLongText:
    return column.textGenerator(table, isAlter)
    # date
  of rdbDate:
    return column.dateGenerator(table, isAlter)
  of rdbDatetime:
    return column.datetimeGenerator(table, isAlter)
  of rdbTime:
    return column.timeGenerator(table, isAlter)
  of rdbTimestamp:
    return column.timestampGenerator(table, isAlter)
  of rdbTimestamps:
    return column.timestampsGenerator(table)
  of rdbSoftDelete:
    return column.softDeleteGenerator(table, isAlter)
    # others
  of rdbBinary:
    return column.blobGenerator(table, isAlter)
  of rdbBoolean:
    return column.boolGenerator(table, isAlter)
  of rdbEnumField:
    return column.enumGenerator(table, isAlter)
  of rdbJson:
    return column.jsonGenerator(table, isAlter)
  # foreign
  of rdbForeign:
    return column.foreignColumnGenerator(table, isAlter)
  of rdbStrForeign:
    return column.strForeignColumnGenerator(table, isAlter)

proc generateForeignString(column:Column, table:Table):string =
  return column.foreignGenerator(table)

proc generateAlterAddForeignString(column:Column, table:Table):string =
  return column.alterAddForeignGenerator(table)

# ==================== public ====================
proc resetTable(self:PostgreQuery, table:Table) =
  self.rdb.raw(&"DROP TABLE IF EXISTS \"{table.name}\"").exec.waitFor


proc getHistories(self:PostgreQuery, table:Table):JsonNode =
  let tables = self.rdb.table("_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table


proc runQuery(self:PostgreQuery, query:seq[string]) =
  for row in query:
    self.rdb.raw(row).exec.waitFor


proc runQueryThenSaveHistory(self:PostgreQuery, tableName:string, query:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for row in query:
      self.rdb.raw(row).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()
  
  self.rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": query.join("; "),
    "checksum": checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor


proc createTableSql(self:PostgreQuery, table:Table) =
  var columnString = ""
  var foreignString = ""
  for i, column in table.columns:
    if i > 0: columnString.add(", ")
    var columnQuery = generateColumnString(column, table)
    columnString.add(columnQuery)
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if columnString.len > 0 or foreignString.len > 0:
        foreignString.add(", ")
        column.query.add(", ")
      let query = generateForeignString(column, table)
      foreignString.add(query)
      columnQuery.add(query)
    column.query.add(columnQuery)

  table.query.add &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({columnString}{foreignString})"
  table.checksum = $table.query.join("; ").secureHash()


proc addColumnSql(self:PostgreQuery, column:Column, table:Table) =
  let columnString = generateColumnString(column, table)
  column.query.add &"ALTER TABLE \"{table.name}\" ADD COLUMN {columnString}"

  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    let foreignString = generateAlterAddForeignString(column, table)
    column.query.add &"ALTER TABLE \"{table.name}\" ADD {foreignString}"
  
  column.checksum = $column.query.join("; ").secureHash()

proc addColumn(self:PostgreQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc changeColumnSql(self:PostgreQuery, column:Column, table:Table) =
  let columnString = generateColumnString(column, table, true)
  let query = &"ALTER TABLE \"{table.name}\" ALTER COLUMN {columnString}"
  column.query.add(query)
  column.checksum = $column.query.join("; ").secureHash()

proc changeColumn(self:PostgreQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc renameColumnSql(self:PostgreQuery, column:Column, table:Table) =
  column.query.add &"ALTER TABLE \"{table.name}\" RENAME COLUMN {column.previousName} TO {column.name}"
  column.checksum = $column.query.join("; ").secureHash()

proc renameColumn(self:PostgreQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc deleteColumnSql(self:PostgreQuery, column:Column, table:Table) =
  column.query.add &"ALTER TABLE \"{table.name}\" DROP COLUMN {column.name}"
  column.checksum = $column.query.join("; ").secureHash()

proc deleteColumn(self:PostgreQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc renameTableSql*(self:PostgreQuery, table:Table) =
  table.query.add &"ALTER TABLE \"{table.previousName}\" RENAME TO \"{table.name}\""
  table.checksum = $table.query.join("; ").secureHash

proc renameTable(self:PostgreQuery, table:Table) =
  self.runQueryThenSaveHistory(table.name, table.query, table.checksum)


proc dropTableSql(self:PostgreQuery, table:Table) =
  table.query.add &"DROP TABLE IF EXISTS \"{table.name}\" CASCADE"
  table.checksum = $table.query.join("; ").secureHash

proc dropTable(self:PostgreQuery, table:Table) =
  self.runQueryThenSaveHistory(table.name, table.query, table.checksum)


proc toInterface*(self:PostgreQuery):IGenerator =
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
