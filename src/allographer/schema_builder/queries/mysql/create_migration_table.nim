import std/asyncdispatch
import std/strformat
import std/options
import std/json
import ../../../query_builder
import ../../enums
import ../../models/table
import ../../models/column
import ../schema_utils
import ./mysql_query_type
import ./sub/create_column_query


proc createMigrationTable*(self: MysqlSchema) =
  var queries:seq[string] = @[]
  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]
  for i, column in self.table.columns:
    if query.len > 0: query.add(", ")
    query.add(createColumnString(self.table, column))
    
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(createForeignKey(self.table, column))
    
    if column.isIndex:
      let logDisplay = self.rdb.log.shouldDisplayLog
      let logFile = self.rdb.log.shouldOutputLogFile
      self.rdb.log.shouldDisplayLog = false
      self.rdb.log.shouldOutputLogFile = false
      defer:
        self.rdb.log.shouldDisplayLog = logDisplay
        self.rdb.log.shouldOutputLogFile = logFile
      let res = self.rdb.raw(&"""
          SELECT count(*) as count
          FROM `INFORMATION_SCHEMA`.`STATISTICS`
          WHERE `TABLE_SCHEMA` = '{self.rdb.info.database}'
          AND `TABLE_NAME` = '{self.table.name}'
          AND `INDEX_NAME` = '{self.table.name}_{column.name}_index'
        """)
        .first()
        .waitFor
      if res.isSome and res.get()["count"].getInt == 0:
        indexQuery.add(createIndexString(self.table, column))

  if foreignQuery.len > 0:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS `{self.table.name}` ({query}, {foreignQuery})"
    )
  else:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS `{self.table.name}` ({query})"
    )

  if indexQuery.len > 0:
    queries.add(indexQuery)

  exec(self.rdb, queries)
