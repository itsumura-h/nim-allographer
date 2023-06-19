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
import ../../enums as schema_builder_enums
import ../../models/table
import ../../models/column
import ../query_interface
import ./query_generator


type SqliteQuery* = ref object
  rdb:Rdb

proc new*(_:type SqliteQuery, rdb:Rdb):SqliteQuery =
  return SqliteQuery(rdb:rdb)


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
    column.query = column.varcharGenerator()
  of rdbChar:
    column.query = column.charGenerator()
  of rdbString:
    column.query = column.varcharGenerator()
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
  if column.isIndex:
    column.indexQuery = column.indexGenerator(table)


proc generateAlterAddForeignString(column:Column):string =
  return column.alterAddForeignGenerator()


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
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query}, {foreignQuery})"
    )
  else:
    table.query.add(
      &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({query})"
    )

  table.query.add(indexQuery)
  table.checksum = $table.query.join("; ").secureHash()


# ==================== add column ====================

proc addColumnSql(self:SqliteQuery, table:Table, column:Column) =
  generateColumnString(column)
  generateForeignString(column)
  generateIndexString(table, column)

  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    column.queries.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN {column.query} {column.foreignQuery}")
  else:
    column.queries.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN {column.query}")

  if column.isIndex:
    column.queries.add(column.indexQuery)

  column.checksum = $column.queries.join("; ").secureHash()


proc addColumn(self:SqliteQuery, table:Table, column:Column) =
  self.execThenSaveHistory(table.name, column.queries, column.checksum)


# ==================== change column ====================

proc changeColumnSql(self:SqliteQuery, table:Table, column:Column) =
  generateColumnString(column)
  column.checksum = $column.query.join("; ").secureHash()


proc changeColumn(self:SqliteQuery, table:Table, column:Column) =
  ## create tmp table with new column difinition
  ##
  ## copy data from existing table to tmp table
  ##
  ## delete existing table
  ##
  ## rename tmp table to existing table
  
  # create tmp table with new column difinition
  #   get existing table schema
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table.name}'"
  var rows = self.rdb.raw(tableDifinitionSql).get.waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")
  let columnRegex = &"'{column.name}'.*?,"
  generateColumnString(column)
  var query = schema.replace(re(columnRegex), column.query & ", ")
  query = query.replace(re",\)", ")")
  query = query.replace(re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
  var isSuccess = false
  try:
    self.rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  # columnString = columnString.replace(",", "")
  self.rdb.table("_migrations").insert(%*{
    "name": table.name,
    "query": query,
    "checksum": $query.secureHash(),
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor

  # # copy data from existing table to tmp table
  query = &"INSERT INTO alter_table_tmp SELECT * FROM {table.name}"
  self.rdb.raw(query).exec.waitFor
  # # delete existing table
  query = &"DROP TABLE IF EXISTS {table.name}"
  self.rdb.raw(query).exec.waitFor
  # rename tmp table to existing table
  query = &"ALTER TABLE alter_table_tmp RENAME TO {table.name}"
  self.rdb.raw(query).exec.waitFor


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
  echo oldColumns
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
