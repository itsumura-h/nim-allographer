import
  std/json,
  std/options,
  std/strformat,
  std/re,
  std/asyncdispatch,
  std/sha1,
  std/times,
  std/strutils,
  std/sequtils,
  ../../../base,
  ../../../query_builder,
  ../../grammers,
  ../query_interface,
  ./impl

type SqliteQuery* = ref object
  rdb:Rdb

proc new*(_:type SqliteQuery, rdb:Rdb):SqliteQuery =
  return SqliteQuery(rdb:rdb)

# ==================== private ====================
proc generateColumnString(column:Column):string =
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
    return column.varcharGenerator()
  of rdbChar:
    return column.charGenerator()
  of rdbString:
    return column.varcharGenerator()
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

proc generateForeignString(column:Column):string =
  return column.foreignGenerator()

proc generateAlterAddForeignString(column:Column):string =
  return column.alterAddForeignGenerator()

# ==================== public ====================
proc resetTable(self:SqliteQuery, table:Table) =
  self.rdb.raw("DROP TABLE IF EXISTS ?", [table.name]).exec.waitFor


proc getHistories(self:SqliteQuery, table:Table):JsonNode =
  let tables = self.rdb.table("_migrations")
            .where("name", "=", table.name)
            .orderBy("created_at", Desc)
            .get()
            .waitFor

  result = newJObject()
  for table in tables:
    result[table["checksum"].getStr] = table


proc runQuery(self:SqliteQuery, query:seq[string]) =
  for row in query:
    self.rdb.raw(row).exec.waitFor


proc runQueryThenSaveHistory(self:SqliteQuery, tableName:string, query:seq[string], checksum:string) =
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


proc createTableSql(self:SqliteQuery, table:Table) =
  var columnString = ""
  var foreignString = ""
  for i, column in table.columns:
    if i > 0: columnString.add(", ")
    var columnQuery = generateColumnString(column)
    columnString.add(columnQuery)
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if columnString.len > 0 or foreignString.len > 0:
        foreignString.add(", ")
        column.query.add(", ")
      let query = generateForeignString(column)
      foreignString.add(query)
      columnQuery.add(query)
    column.query.add(columnQuery)

  table.query.add &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({columnString}{foreignString})"
  table.checksum = $table.query.join("; ").secureHash()


proc addColumnSql(self:SqliteQuery, column:Column, table:Table) =
  let columnString = generateColumnString(column)

  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    let foreignString = generateAlterAddForeignString(column)
    column.query.add &"ALTER TABLE \"{table.name}\" ADD COLUMN {columnString} {foreignString}"
  else:
    column.query.add &"ALTER TABLE \"{table.name}\" ADD COLUMN {columnString}"
  column.checksum = $column.query.join("; ").secureHash()

proc addColumn(self:SqliteQuery, column:Column, table:Table) =
  self.runQueryThenSaveHistory(table.name, column.query, column.checksum)


proc changeColumnSql(self:SqliteQuery, column:Column, table:Table) =
  column.query.add generateColumnString(column)
  column.checksum = $column.query.join("; ").secureHash()

proc changeColumn(self:SqliteQuery, column:Column, table:Table) =
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
  var rows = self.rdb.raw(tableDifinitionSql).getRaw.waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")
  let columnRegex = &"'{column.name}'.*?,"
  var columnString = generateColumnString(column) & ","
  var query = schema.replace(re(columnRegex), columnString)
  query = query.replace(re",\)", ")")
  query = query.replace(re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
  
  var isSuccess = false
  try:
    self.rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  columnString = columnString.replace(",", "")
  self.rdb.table("_migrations").insert(%*{
    "name": table.name,
    "query": columnString,
    "checksum": $columnString.secureHash,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor

  # copy data from existing table to tmp table
  query = &"INSERT INTO alter_table_tmp SELECT * FROM {table.name}"
  self.rdb.raw(query).exec.waitFor
  # delete existing table
  query = &"DROP TABLE IF EXISTS {table.name}"
  self.rdb.raw(query).exec.waitFor
  # rename tmp table to existing table
  query = &"ALTER TABLE alter_table_tmp RENAME TO {table.name}"
  self.rdb.raw(query).exec.waitFor


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
  var rows = self.rdb.raw(tableDifinitionSql).getRaw.waitFor
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
  var rows = self.rdb.raw(tableDifinitionSql).getRaw.waitFor
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


proc renameTableSql*(self:SqliteQuery, table:Table) =
  table.query.add &"ALTER TABLE \"{table.previousName}\" RENAME TO \"{table.name}\""
  table.checksum = $table.query.join("; ").secureHash

proc renameTable(self:SqliteQuery, table:Table) =
  var isSuccess = false
  try:
    for row in table.query:
      self.rdb.raw(row).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  self.rdb.table("_migrations").insert(%*{
    "name": table.name,
    "query": table.query,
    "checksum": table.checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor


proc dropTableSql(self:SqliteQuery, table:Table) =
  table.query.add &"DROP TABLE IF EXISTS \"{table.name}\""
  table.checksum = $table.query.join("; ").secureHash

proc dropTable(self:SqliteQuery, table:Table) =
  var isSuccess = false
  try:
    for row in table.query:
      self.rdb.raw(row).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  self.rdb.table("_migrations").insert(%*{
    "name": table.name,
    "query": table.query.join("; "),
    "checksum": table.checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor

proc toInterface*(self:SqliteQuery):IGenerator =
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
