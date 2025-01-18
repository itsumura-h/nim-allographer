import std/asyncdispatch
import std/strformat
import std/strutils
import std/sequtils
import std/sha1
import std/json
import ../../../../query_builder
import ../../enums
import ../../models/table
import ../../models/column
import ./schema_utils
import ./mysql_query_type
import ./sub/create_column_query
import ./sub/is_exists


proc createTable*(self: MysqlSchema, isReset:bool) =
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

      if not isExistsIndex(self.rdb, self.table, column).waitFor():
        if [rdbText, rdbMediumText,rdbLongText, rdbBinary, rdbJson].contains(column.typ):
          dbError("BLOB, TEXT and JSON column can't use index")
        indexQuery.add(createIndexString(self.table, column))

  if self.table.primary.len > 0:
    let primary = self.table.primary.map(
        proc(row:string):string =
          return &"`{row}`"
      )
      .join(", ")
    query.add(&", PRIMARY KEY({primary})")

  if foreignQuery.len > 0:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS `{self.table.name}` ({query}, {foreignQuery})"
    )
  else:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS `{self.table.name}` ({query})"
    )

  if self.table.commentContent.len > 0:
    queries[^1].add(
      &" COMMENT = '{self.table.commentContent}'"
    )

  if indexQuery.len > 0:
    queries.add(indexQuery)

  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
