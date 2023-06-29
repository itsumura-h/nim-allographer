import std/asyncdispatch
import std/json
import std/re
import std/sequtils
import std/strformat
import std/strutils
import std/sha1
import std/times
import ../../../query_builder/enums as query_builder_enums
import ../../../query_builder/rdb/rdb_types
import ../../../query_builder/rdb/rdb_interface
import ../../../query_builder/rdb/query/grammar
import ../../../query_builder/error
import ../../enums as schema_builder_enums
import ../../models/table
import ../../models/column
import ../query_interface
import ./create_table_generator
import ./add_column_generator


type SqliteQuery* = ref object
  rdb:Rdb

proc new*(_:type SqliteQuery, rdb:Rdb):SqliteQuery =
  return SqliteQuery(rdb:rdb)


# ==================== private ====================

proc createColumnString(column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.query = column.createSerialColumn()
  of rdbInteger:
    column.query = column.createIntColumn()
  of rdbSmallInteger:
    column.query = column.createIntColumn()
  of rdbMediumInteger:
    column.query = column.createIntColumn()
  of rdbBigInteger:
    column.query = column.createIntColumn()
    # float
  of rdbDecimal:
    column.query = column.createDecimalColumn()
  of rdbDouble:
    column.query = column.createDecimalColumn()
  of rdbFloat:
    column.query = column.createFloatColumn()
    # char
  of rdbUuid:
    column.query = column.createUuidColumn()
  of rdbChar:
    column.query = column.createCharColumn()
  of rdbString:
    column.query = column.createVarcharColumn()
    # text
  of rdbText:
    column.query = column.createTextColumn()
  of rdbMediumText:
    column.query = column.createTextColumn()
  of rdbLongText:
    column.query = column.createTextColumn()
    # date
  of rdbDate:
    column.query = column.createDateColumn()
  of rdbDatetime:
    column.query = column.createDatetimeColumn()
  of rdbTime:
    column.query = column.createTimeColumn()
  of rdbTimestamp:
    column.query = column.createTimestampColumn()
  of rdbTimestamps:
    column.query = column.createTimestampsColumn()
  of rdbSoftDelete:
    column.query = column.createSoftDeleteColumn()
    # others
  of rdbBinary:
    column.query = column.createBlobColumn()
  of rdbBoolean:
    column.query = column.createBoolColumn()
  of rdbEnumField:
    column.query = column.createEnumColumn()
  of rdbJson:
    column.query = column.createJsonColumn()
  # foreign
  of rdbForeign:
    column.query = column.createForeignColumn()
  of rdbStrForeign:
    column.query = column.createStrForeignColumn()


proc createForeignString(column:Column) =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.foreignQuery = column.createForeignKey()


proc generateIndexString(table:Table, column:Column) =
  if table.migrationType == CreateTable:
    if column.isIndex:
      column.indexQuery = column.createIndexColumn(table)
  elif table.migrationType == ChangeTable:
    if column.migrationType == AddColumn:
      if column.isUnique:
        column.indexQuery = column.addUniqueColumn(table)
      elif column.isIndex:
        column.indexQuery = column.addIndexColumn(table)


# ==================== public ====================

proc resetMigrationTable(self:SqliteQuery, table:Table) =
  self.rdb.table("_migrations").where("name", "=", table.name).delete.waitFor

proc resetTable(self:SqliteQuery, table:Table) =
  self.rdb.raw(&"DROP TABLE IF EXISTS \"{table.name}\"").exec.waitFor


proc getHistories(self:SqliteQuery, table:Table):JsonNode =
  let tables = self.rdb.table("_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table

proc shouldRunAddColumn(self:SqliteQuery, column:Column, isReset:bool):bool =
  if isReset:
    return true
  


proc exec*(self:SqliteQuery, table:Table) =
  for row in table.query:
    self.rdb.raw(row).exec.waitFor


proc execThenSaveHistory(self:SqliteQuery, tableName:string, queries:seq[string], checksum:string) =
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

proc createTableSql(self:SqliteQuery, table:Table) =
  for i, column in table.columns:
    createColumnString(column)
    createForeignString(column)
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
    
    if column.isUnique or column.isIndex:
      indexQuery.add(column.indexQuery)

  if foreignQuery.len > 0:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query}, {foreignQuery})"
    )
  else:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query})"
    )

  if indexQuery.len > 0:
    table.query.add(indexQuery)

  table.checksum = $table.query.join("; ").secureHash()


# ==================== add column ====================

proc addColumnSql(self:SqliteQuery, table:Table, column:Column) =
  case column.typ
  of rdbIncrements:
    createColumnString(column)
    column.queries = addSerialColumn(self.rdb, table, column)
  of rdbInteger:
    column.queries = addIntColumn(table, column)
  of rdbSmallInteger:
    column.queries = addIntColumn(table, column)
  of rdbMediumInteger:
    column.queries = addIntColumn(table, column)
  of rdbBigInteger:
    column.queries = addIntColumn(table, column)
    # float
  of rdbDecimal:
    column.queries = addDecimalColumn(table, column)
  of rdbDouble:
    column.queries = addDecimalColumn(table, column)
  of rdbFloat:
    column.queries = addFloatColumn(table, column)
    # char
  of rdbUuid:
    column.queries = addUuidColumn(table, column)
  of rdbChar:
    column.queries = addCharColumn(table, column)
  of rdbString:
    column.queries = addVarcharColumn(table, column)
    # text
  of rdbText:
    column.queries = addTextColumn(table, column)
  of rdbMediumText:
    column.queries = addTextColumn(table, column)
  of rdbLongText:
    column.queries = addTextColumn(table, column)
    # date
  of rdbDate:
    column.queries = addDateColumn(table, column)
  of rdbDatetime:
    column.queries = addDatetimeColumn(table, column)
  of rdbTime:
    column.queries = addTimeColumn(table, column)
  of rdbTimestamp:
    column.queries = addTimestampColumn(table, column)
  of rdbTimestamps:
    column.queries = addTimestampsColumn(table, column)
  of rdbSoftDelete:
    column.queries = addSoftDeleteColumn(table, column)
    # others
  of rdbBinary:
    column.queries = addBlobColumn(table, column)
  of rdbBoolean:
    column.queries = addBoolColumn(table, column)
  of rdbEnumField:
    column.queries = addEnumColumn(table, column)
  of rdbJson:
    column.queries = addJsonColumn(table, column)
  # foreign
  of rdbForeign:
    column.queries = addForeignColumn(table, column)
  of rdbStrForeign:
    column.queries = addStrForeignColumn(table, column)

  generateIndexString(table, column)
  if column.indexQuery.len > 0:
    column.queries.add(column.indexQuery)

  column.checksum = $column.queries.join("; ").secureHash()


proc addColumn(self:SqliteQuery, table:Table, column:Column) =
  self.execThenSaveHistory(table.name, column.queries, column.checksum)


# ==================== change column ====================

proc changeColumnSql(self:SqliteQuery, table:Table, column:Column) =
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table.name}'"
  var rows = self.rdb.raw(tableDifinitionSql).get.waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")
  echo "=== schema"
  echo schema
  # 外部キー部分を抜き出す

  let columnRegex = &"'{column.name}'.*?,"
  createColumnString(column)
  createForeignString(column)
  if column.foreignQuery.len > 0:
    column.query = column.query & ", " & column.foreignQuery
  var query = schema.replace(re(columnRegex), column.query & ",")
  query = query.replace(re",\)", ")")
  query = query.replace(re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
  column.queries.add(query)

  # copy data from existing table to tmp table
  query = &"INSERT INTO alter_table_tmp SELECT * FROM {table.name}"
  column.queries.add(query)
  # delete existing table
  query = &"DROP TABLE IF EXISTS {table.name}"
  column.queries.add(query)
  # rename tmp table to existing table
  query = &"ALTER TABLE alter_table_tmp RENAME TO {table.name}"
  column.queries.add(query)
  column.checksum = $column.queries.join("; ").secureHash()


proc changeColumn(self:SqliteQuery, table:Table, column:Column) =
  ## create tmp table with new column difinition
  ##
  ## copy data from old table to tmp table
  ##
  ## delete old table
  ##
  ## rename tmp table name to old table name
  
  # create tmp table with new column difinition
  #   get existing table schema
  self.execThenSaveHistory(table.name, column.queries, column.checksum)
  


# ==================== rename column ====================

proc renameColumnSql(self:SqliteQuery, column:Column, table:Table) =
  column.query.add &"rename {column.previousName} to {column.name} in {table.name}"
  column.checksum = $column.query.join("; ").secureHash()

proc renameColumn(self:SqliteQuery, column:Column, table:Table) =
  ## create tmp table with new column difinition
  ##
  ## copy data from existing table to tmp table
  ##
  ## delete existing table
  ##
  ## rename tmp table to existing table
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table.name}'"
  var rows = self.rdb.raw(tableDifinitionSql).get.waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")
  let columnRegex = &"'{column.previousName}'.*?,"

  var columnString = rows[0]["sql"].getStr.findAll(re(columnRegex))[0]
  columnString = columnString.multiReplace(
    (column.previousName, column.name)
  )
  var query = schema.replace(re(columnRegex), columnString)
  query = query.replace(re",\)", ")")
  query = query.replace(re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")

  var isSuccess = false
  try:
    self.rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  self.rdb.table("_migrations").insert(%*{
    "name": table.name,
    "query": column.query,
    "checksum": column.checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor

  # copy data from existing table to tmp table
  let oldColumns = self.rdb.table(table.name).columns().waitFor
  let newColumns = oldColumns.map(
    proc(x:string):string =
      if x == column.previousName:
        return column.name
      else:
        return x
  )
  let oldColumnsName = oldColumns.join(", ")
  let newColumnsName = newColumns.join(", ")
  query = &"INSERT INTO alter_table_tmp({newColumnsName}) SELECT {oldColumnsName} FROM \"{table.name}\""
  self.rdb.raw(query).exec.waitFor
  # delete existing table
  query = &"DROP TABLE IF EXISTS \"{table.name}\""
  self.rdb.raw(query).exec.waitFor
  # rename tmp table to existing table
  query = &"ALTER TABLE alter_table_tmp RENAME TO \"{table.name}\""
  self.rdb.raw(query).exec.waitFor


proc deleteColumnSql(self:SqliteQuery, column:Column, table:Table) =
  column.query.add &"delete {column.name} in {table.name}"
  column.checksum = $column.query.join("; ").secureHash()

proc deleteColumn(self:SqliteQuery, column:Column, table:Table) =
  ## create tmp table with new column difinition
  ##
  ## copy data from existing table to tmp table
  ##
  ## delete existing table
  ##
  ## rename tmp table to existing table
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table.name}'"
  var rows = self.rdb.raw(tableDifinitionSql).get.waitFor
  var query = replace(rows[0]["sql"].getStr, re"\)$", ", )")
  
  var columnString = query.findAll(re(&"'{column.name}'.*?,\\s"))[0]
  query = query.replace(columnString, "")

  let columnStringArr = query.findAll(re(&"FOREIGN KEY\\('{column.name}'\\).*?,\\s"))
  if columnStringArr.len > 0:
    columnString = columnStringArr[0]
    query = query.replace(columnString, "")
  
  query = query.replace(", )", ")")
  query = query.replace(re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")

  var isSuccess = false
  try:
    self.rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  self.rdb.table("_migrations").insert(%*{
    "name": table.name,
    "query": column.query,
    "checksum": column.checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor

  # copy data from existing table to tmp table
  var columns = self.rdb.table(table.name).columns().waitFor
  columns = columns.filter(proc(x:string):bool = x != column.name)
  let columnsName = columns.join(", ")
  query = &"INSERT INTO alter_table_tmp({columnsName}) SELECT {columnsName} FROM \"{table.name}\""
  self.rdb.raw(query).exec.waitFor
  # delete existing table
  query = &"DROP TABLE IF EXISTS \"{table.name}\""
  self.rdb.raw(query).exec.waitFor
  # rename tmp table to existing table
  query = &"ALTER TABLE alter_table_tmp RENAME TO \"{table.name}\""
  self.rdb.raw(query).exec.waitFor


proc toInterface*(self:SqliteQuery):IGenerator =
  return (
    resetMigrationTable:proc(table:Table) = self.resetMigrationTable(table),
    resetTable:proc(table:Table) = self.resetTable(table),
    getHistories:proc(table:Table):JsonNode = self.getHistories(table),
    shouldRunAddColumn:proc(column:Column, isReset:bool):bool = self.shouldRunAddColumn(column, isReset),
    exec:proc(table:Table) = self.exec(table),
    execThenSaveHistory:proc(tableName:string, query:seq[string], checksum:string) = self.execThenSaveHistory(tableName, query, checksum),
    createTableSql:proc(table:Table) = self.createTableSql(table),
    addColumnSql:proc(table:Table, column:Column) = self.addColumnSql(table, column),
    addColumn:proc(table:Table, column:Column) = self.addColumn(table, column),
    changeColumnSql:proc(table:Table, column:Column) = self.changeColumnSql(table, column),
    changeColumn:proc(table:Table, column:Column) = self.changeColumn(table, column),
    # renameColumnSql:proc(column:Column, table:Table) = self.renameColumnSql(column, table),
    # renameColumn:proc(column:Column, table:Table) = self.renameColumn(column, table),
    # deleteColumnSql:proc(column:Column, table:Table) = self.deleteColumnSql(column, table),
    # deleteColumn:proc(column:Column, table:Table) = self.deleteColumn(column, table),
  #   renameTableSql:proc(table:Table) = self.renameTableSql(table),
  #   renameTable:proc(table:Table) = self.renameTable(table),
  #   dropTableSql:proc(table:Table) = self.dropTableSql(table),
  #   dropTable:proc(table:Table) = self.dropTable(table),
  )
