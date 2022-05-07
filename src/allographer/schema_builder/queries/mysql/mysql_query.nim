import
  std/json,
  std/options,
  std/strformat,
  std/asyncdispatch,
  std/sha1,
  std/times,
  std/strutils,
  ../../../base,
  ../../../query_builder,
  ../../grammers,
  ../query_interface,
  ./impl


type MysqlQuery* = ref object
  rdb:Rdb

proc new*(_:type MysqlQuery, rdb:Rdb):MysqlQuery =
  return MysqlQuery(rdb:rdb)


# ==================== private ====================
proc generateColumnString(column:Column, table:Table):string =
  case column.typ:
    # int
  of rdbIncrements:
    return column.serialGenerator()
  of rdbInteger:
    return column.intGenerator()
  of rdbSmallInteger:
    return column.intGenerator()
  of rdbMediumInteger:
    return column.intGenerator()
  of rdbBigInteger:
    return column.intGenerator()
    # float
  of rdbDecimal:
    return column.decimalGenerator()
  of rdbDouble:
    return column.decimalGenerator()
  of rdbFloat:
    return column.floatGenerator()
    # char
  of rdbUuid:
    return column.stringGenerator()
  of rdbChar:
    return column.charGenerator()
  of rdbString:
    return column.stringGenerator()
    # text
  of rdbText:
    return column.textGenerator()
  of rdbMediumText:
    return column.textGenerator()
  of rdbLongText:
    return column.textGenerator()
    # date
  of rdbDate:
    return column.dateGenerator()
  of rdbDatetime:
    return column.datetimeGenerator()
  of rdbTime:
    return column.timeGenerator()
  of rdbTimestamp:
    return column.timestampGenerator()
  of rdbTimestamps:
    return column.timestampsGenerator()
  of rdbSoftDelete:
    return column.softDeleteGenerator()
    # others
  of rdbBinary:
    return column.blobGenerator()
  of rdbBoolean:
    return column.boolGenerator()
  of rdbEnumField:
    return column.enumGenerator()
  of rdbJson:
    return column.jsonGenerator()
  # foreign
  of rdbForeign:
    return column.foreignColumnGenerator()
  of rdbStrForeign:
    return column.strForeignColumnGenerator()

proc generateForeignString(column:Column, table:Table):string =
  return column.foreignGenerator()

proc generateAlterAddForeignString(column:Column, table:Table):string =
  return column.alterAddForeignGenerator(table)

# ==================== public ====================
proc resetTable(self:MysqlQuery, table:Table) =
  self.rdb.raw(&"DROP TABLE IF EXISTS `{table.name}` CASCADE").exec.waitFor


proc getHistories(self:MysqlQuery, table:Table):JsonNode =
  let tables = self.rdb.table("allographer_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table


proc runQuery(self:MysqlQuery, query:seq[string]) =
  for row in query:
    self.rdb.raw(row).exec.waitFor


proc runQueryThenSaveHistory(self:MysqlQuery, tableName:string, query:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for row in query:
      self.rdb.raw(row).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()
  
  self.rdb.table("allographer_migrations").insert(%*{
    "name": tableName,
    "query": query.join("; "),
    "checksum": checksum,
    "created_at": $now().format("yyyy-MM-dd HH:mm:ss"),
    "status": isSuccess
  })
  .waitFor

proc createTableSql(self:MysqlQuery, table:Table) =
  var columnString = ""
  var foreignString = ""
  for i, column in table.columns:
    if i > 0: columnString.add(", ")
    var query = generateColumnString(column, table)
    columnString.add(query)
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if columnString.len > 0 or foreignString.len > 0:
        foreignString.add(", ")
        query.add(", ")
      let columnQuery = generateForeignString(column, table)
      foreignString.add(columnQuery)
      query.add(columnQuery)
    column.query.add query

  table.query.add &"CREATE TABLE IF NOT EXISTS `{table.name}` ({columnString}{foreignString})"
  table.checksum = $table.query.join("; ").secureHash()


proc addColumnSql(self:MysqlQuery, column:Column, table:Table) =
  let columnString = generateColumnString(column, table)

  column.query.add &"ALTER TABLE `{table.name}` ADD COLUMN {columnString}"

  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    let foreignString = generateAlterAddForeignString(column, table)
    column.query.add(&"ALTER TABLE `{table.name}` ADD {foreignString}")
  column.checksum = $column.query.join("; ").secureHash()


proc addColumn(self:MysqlQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc changeColumnSql(self:MysqlQuery, column:Column, table:Table) =
  let columnString = generateColumnString(column, table)
  let query = &"ALTER TABLE `{table.name}` MODIFY COLUMN {columnString}"
  column.query.add(query)
  column.checksum = $column.query.join("; ").secureHash()


proc changeColumn(self:MysqlQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc renameColumnSql(self:MysqlQuery, column:Column, table:Table) =
  let query = &"ALTER TABLE `{table.name}` RENAME COLUMN `{column.previousName}` TO `{column.name}`"
  column.query.add(query)
  column.checksum = $column.query.join("; ").secureHash()


proc renameColumn(self:MysqlQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc deleteColumnSql(self:MysqlQuery, column:Column, table:Table) =
  column.query.add(&"ALTER TABLE `{table.name}` DROP `{column.name}`")
  column.checksum = $column.query.join("; ").secureHash()

proc deleteColumn(self:MysqlQuery, column:Column, table:Table) =
  let res = self.rdb.raw(&"SHOW CREATE TABLE `{table.name}`").getRaw().waitFor
  var keyName = ""
  var hasIndex = false
  let query = res[0]["Create Table"].getStr
  for row in query.splitLines:
    if row.contains("CONSTRAINT") and row.contains(column.name):
      hasIndex = true
      keyName = row.strip().splitWhitespace()[1].replace("`", "")
      break

  if hasIndex:
    column.query.insert(
      &"ALTER TABLE `{table.name}` DROP FOREIGN KEY `{keyName}`",
      0
    )
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc renameTableSql(self:MysqlQuery, table:Table) =
  let query = &"ALTER TABLE `{table.previousName}` RENAME TO `{table.name}`"
  table.query.add(query)
  table.checksum = $table.query.join("; ").secureHash()

proc renameTable(self:MysqlQuery, table:Table) =
  self.runQueryThenSaveHistory(table.name, table.query, table.checksum)
  
proc dropTableSql(self:MysqlQuery, table:Table) =
  let query = &"DROP TABLE IF EXISTS `{table.name}`"
  table.query.add(query)
  table.checksum = $table.query.join("; ").secureHash()

proc dropTable(self:MysqlQuery, table:Table) =
  self.runQueryThenSaveHistory(table.name, table.query, table.checksum)


proc toInterface*(self:MysqlQuery):IGenerator =
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
