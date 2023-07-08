import std/asyncdispatch
import std/strutils
import std/strformat
import std/sha1
import std/options
import std/json
import std/times
import ../../../query_builder
import ../../models/table
import ../../models/column
import ../../enums
import ./mysql_query_type
import ./sub/change_column_query


proc shouldRun(rdb:Rdb, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  let history = rdb.table("_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc execThenSaveHistory(rdb:Rdb, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let query = queries.join("; ")
  rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": query,
    "checksum": checksum,
    "created_at": $now().utc.format("yyyy-MM-dd HH:mm:ss'.'fff"),
    "status": isSuccess
  })
  .waitFor


proc changeColumn*(self:MysqlQuery, isReset:bool) =
  ## add tmp column with new definition
  ## move data from old column to tmp colun
  ## change tmp column name to new column name

  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  let columnName = self.column.name
  self.column.name = "alter_tmp_column"
  changeColumnString(self.table, self.column)
  self.column.name = columnName
  var queries = self.column.queries
  queries.add(&"INSERT INTO `{self.table.name}`(`alter_tmp_column`) SELECT `{columnName}` FROM `{self.table.name}`")
  queries.add(&"ALTER TABLE `{self.table.name}` DROP CONSTRAINT IF EXISTS `{self.table.name}_{columnName}_fkey`")
  queries.add(&"ALTER TABLE `{self.table.name}` DROP COLUMN `{columnName}`")
  queries.add(&"ALTER TABLE `{self.table.name}` RENAME COLUMN `alter_tmp_column` TO `{columnName}`")
  if self.column.typ == rdbForeign or self.column.typ == rdbStrForeign:
    let foreignQuery = changeForeignKey(self.column, self.table)
    queries.add(foreignQuery)
  if self.column.isIndex:
    let indexQuery = addIndexString(self.column, self.table)
    queries.add(indexQuery)

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
